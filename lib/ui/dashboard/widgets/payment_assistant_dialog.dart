import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/payment_model.dart';
import '../../../models/party_model.dart';
import '../../../models/invoice_model.dart';
import '../../../services/payment_assistant_service.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/party_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/auth_provider.dart';

enum ChatStep { input, review }

class PaymentAssistantDialog extends ConsumerStatefulWidget {
  const PaymentAssistantDialog({super.key});

  @override
  ConsumerState<PaymentAssistantDialog> createState() =>
      _PaymentAssistantDialogState();
}

class _PaymentAssistantDialogState extends ConsumerState<PaymentAssistantDialog>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatStep _step = ChatStep.input;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  // For Typing Animation
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processRapidEntry() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final assistant = ref.read(paymentAssistantServiceProvider);
      _result = await assistant.processRapidEntry(_controller.text.trim());

      setState(() {
        _step = ChatStep.review;
      });
      _scrollToBottom();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Extraction failed') ||
          errorMessage.contains('FirebaseFunctionsException')) {
        errorMessage =
            "I'm having trouble connecting to my AI brain. Please try again.";
      } else if (errorMessage.length > 80) {
        errorMessage = "An unexpected error occurred. Please try again.";
      }

      setState(() {
        _error = errorMessage;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndSave() async {
    if (_result == null) return;

    setState(() => _isLoading = true);
    _error = null;

    try {
      final type = _result!['type'];
      final bool shouldCreateParty = _result!['shouldCreateParty'] ?? false;

      String partyId;
      String partyName;

      if (shouldCreateParty) {
        partyName = _result!['partyName'];
        partyId = await _createParty(
          partyName,
          type == 'purchase' ? 'supplier' : 'customer',
        );
      } else {
        final party = _result!['matchedParty'] as Party;
        partyId = party.id;
        partyName = party.name;
      }

      if (type == 'payment') {
        await _recordPayment(partyId, partyName);
      } else {
        await _recordInvoice(partyId, partyName);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Transaction recorded successfully.'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.length > 80) {
        errorMessage = "An error occurred while saving. Please try again.";
      }
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<String> _createParty(String name, String type) async {
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final repo = ref.read(partyRepositoryProvider);
    final newParty = Party(
      id: '',
      userId: userId,
      partyType: type,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await repo.createParty(newParty);
  }

  Future<void> _recordPayment(String partyId, String partyName) async {
    final repo = ref.read(paymentRepositoryProvider);
    final payment = Payment(
      id: '',
      partyId: partyId,
      partyName: partyName,
      paymentType:
          _result!['paymentType'] ??
          (_result!['matchedParty']?.partyType == 'supplier'
              ? 'payment'
              : 'receipt'),
      paymentDate: _result!['date'] != null
          ? DateTime.parse(_result!['date'])
          : DateTime.now(),
      totalAmount: (_result!['amount'] as num).toDouble(),
      paymentMethod: _result!['paymentMethod'] ?? 'other',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final List<PaymentAllocation> allocations = [];
    if (_result!['allocations'] != null) {
      for (var a in (_result!['allocations'] as List)) {
        allocations.add(
          PaymentAllocation(
            invoiceId: a['invoiceId'],
            invoiceNumber: a['invoiceNumber'],
            allocatedAmount: (a['allocatedAmount'] as num).toDouble(),
          ),
        );
      }
    }

    await repo.recordPayment(payment, allocations);
  }

  Future<void> _recordInvoice(String partyId, String partyName) async {
    final repo = ref.read(invoiceRepositoryProvider);
    final invoice = Invoice(
      id: '',
      partyId: partyId,
      partyName: partyName,
      invoiceType: _result!['type'] == 'sale' ? 'sales' : 'purchase',
      invoiceNumber:
          _result!['invoiceNumber'] ??
          'INV-${DateTime.now().millisecondsSinceEpoch}',
      docType: 'Invoice/Bill',
      invoiceDate: _result!['date'] != null
          ? DateTime.parse(_result!['date'])
          : DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      totalAmount: (_result!['amount'] as num).toDouble(),
      paidAmount: 0.0,
      outstandingAmount: (_result!['amount'] as num).toDouble(),
      paymentStatus: 'unpaid',
      notes: _result!['notes'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.createInvoice(invoice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 0,
            right: 0,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pulse AI Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32, thickness: 0.5),

              // Chat Content
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _aiBubble(
                        "Hi! I'm your Pulse Assistant. Describe your entry (e.g., '50k from Canopas' or 'Purchase 10k from New Vendor') and I'll handle the record for you.",
                      ),
                      if (_result != null) _userBubble(_controller.text),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStep(),
                      ),
                      if (_isLoading) _buildTypingIndicator(),
                      if (_error != null) _errorIndicator(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _aiBubble(String text) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 40),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.8),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                double delay = index * 0.2;
                double value =
                    (sin((_typingController.value * 2 * pi) + delay) + 1) / 2;
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3 + (value * 0.7)),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isLoading) return const SizedBox.shrink();

    switch (_step) {
      case ChatStep.input:
        return _buildInputArea();
      case ChatStep.review:
        return _buildReviewCard();
    }
  }

  Widget _buildInputArea() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Type entry...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _processRapidEntry(),
            ),
          ),
          IconButton(
            onPressed: _processRapidEntry,
            icon: const Icon(Icons.send_rounded, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final bool shouldCreate = _result!['shouldCreateParty'];
    final String partyName = shouldCreate
        ? _result!['partyName']
        : (_result!['matchedParty'] as Party).name;
    final type = _result!['type'];
    final amount = (_result!['amount'] as num).toDouble();

    String message = "";
    if (shouldCreate) {
      message =
          "New Party '$partyName' detected. Creating record and adding a ${fmt.format(amount)} ${type == 'payment' ? 'Payment' : (type == 'sale' ? 'Sale' : 'Purchase')}. Save?";
    } else {
      String action = type == 'payment'
          ? 'Payment'
          : (type == 'sale' ? 'Sale' : 'Purchase');
      String extra =
          (type == 'payment' &&
              _result!['allocations'] != null &&
              (_result!['allocations'] as List).isNotEmpty)
          ? " and allocating to Invoice #${(_result!['allocations'] as List).first['invoiceNumber']}"
          : "";
      message =
          "Found '$partyName'. Recording a ${fmt.format(amount)} $action$extra. Save?";
    }

    return Column(
      children: [
        _aiBubble(message),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _step = ChatStep.input;
                _result = null;
              }),
              child: const Text('Cancel/Edit'),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton(
                onPressed: _confirmAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirm & Save',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
