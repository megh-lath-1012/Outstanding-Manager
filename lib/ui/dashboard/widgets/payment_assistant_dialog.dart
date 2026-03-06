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

enum ChatStep { actionSelection, partySelection, transactionDetails, review }

class PaymentAssistantDialog extends ConsumerStatefulWidget {
  const PaymentAssistantDialog({super.key});

  @override
  ConsumerState<PaymentAssistantDialog> createState() =>
      _PaymentAssistantDialogState();
}

class _PaymentAssistantDialogState extends ConsumerState<PaymentAssistantDialog>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatStep _step = ChatStep.actionSelection;
  String? _selectedAction; // 'sale', 'purchase', 'payment'
  Party? _selectedParty;
  bool _isLoading = false;
  Map<String, dynamic>? _extractedData;
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
    _searchController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _nextStep(ChatStep next) {
    setState(() {
      _step = next;
      _error = null;
    });
    _scrollToBottom();
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

  Future<void> _processPrompt() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final assistant = ref.read(paymentAssistantServiceProvider);

      if (_selectedAction == 'payment') {
        _extractedData = await assistant.processPaymentPrompt(
          _controller.text.trim(),
        );
      } else {
        _extractedData = await assistant.processTransactionPrompt(
          prompt: _controller.text.trim(),
          type: _selectedAction!,
        );
      }

      _nextStep(ChatStep.review);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndRecord() async {
    if (_extractedData == null) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedAction == 'payment') {
        await _recordPayment();
      } else {
        await _recordInvoice();
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
                Text(
                  '${_selectedAction![0].toUpperCase()}${_selectedAction!.substring(1)} recorded successfully.',
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _recordPayment() async {
    final repo = ref.read(paymentRepositoryProvider);
    final payment = Payment(
      id: '',
      partyId: _extractedData!['partyId'] ?? _selectedParty!.id,
      partyName: _extractedData!['partyName'] ?? _selectedParty!.name,
      paymentType: _extractedData!['paymentType'],
      paymentDate: DateTime.parse(_extractedData!['paymentDate']),
      totalAmount: (_extractedData!['totalAmount'] as num).toDouble(),
      paymentMethod: _extractedData!['paymentMethod'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final List<PaymentAllocation> allocations =
        (_extractedData!['allocations'] as List)
            .map(
              (a) => PaymentAllocation(
                invoiceId: a['invoiceId'],
                invoiceNumber: a['invoiceNumber'],
                allocatedAmount: (a['allocatedAmount'] as num).toDouble(),
              ),
            )
            .toList();

    await repo.recordPayment(payment, allocations);
  }

  Future<void> _recordInvoice() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final invoice = Invoice(
      id: '',
      partyId: _selectedParty!.id,
      partyName: _selectedParty!.name,
      invoiceType: _selectedAction == 'sale' ? 'sales' : 'purchase',
      invoiceNumber:
          _extractedData!['invoiceNumber'] ??
          'INV-${DateTime.now().millisecondsSinceEpoch}',
      docType: 'Invoice/Bill',
      invoiceDate: _extractedData!['date'] != null
          ? DateTime.parse(_extractedData!['date'])
          : DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      totalAmount: (_extractedData!['totalAmount'] as num).toDouble(),
      paidAmount: 0.0,
      outstandingAmount: (_extractedData!['totalAmount'] as num).toDouble(),
      paymentStatus: 'unpaid',
      notes: _extractedData!['notes'],
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Assistant',
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
                      _buildChatHistory(),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStep(),
                      ),
                      if (_isLoading) _buildTypingIndicator(),
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

  Widget _buildChatHistory() {
    // This builds the history of what has been selected/done so far
    List<Widget> history = [];

    // Initial Greeting
    history.add(
      _aiBubble('Hello! I\'m your AI Assistant. How can I help you today?'),
    );

    if (_selectedAction != null) {
      String actionText = '';
      if (_selectedAction == 'sale') actionText = 'I want to record a Sale';
      if (_selectedAction == 'purchase')
        actionText = 'I want to record a Purchase';
      if (_selectedAction == 'payment')
        actionText = 'I want to record a Payment';
      history.add(_userBubble(actionText));

      String partyPrompt =
          'Who is the ${_selectedAction == 'purchase' ? 'supplier' : 'customer'}?';
      history.add(_aiBubble(partyPrompt));
    }

    if (_selectedParty != null) {
      history.add(_userBubble(_selectedParty!.name));
      String detailsPrompt = _selectedAction == 'payment'
          ? 'Great! Tell me about the payment from ${_selectedParty!.name}.'
          : 'Understood. Please describe the $_selectedAction details for ${_selectedParty!.name}.';
      history.add(_aiBubble(detailsPrompt));
    }

    return Column(children: history);
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
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
    switch (_step) {
      case ChatStep.actionSelection:
        return _buildActionChoices();
      case ChatStep.partySelection:
        return _buildPartyChoices();
      case ChatStep.transactionDetails:
        return _buildTransactionInput();
      case ChatStep.review:
        return _buildReviewCard();
    }
  }

  Widget _buildActionChoices() {
    return Column(
      children: [
        _futuristicChoiceButton(
          label: 'Record a Sale',
          icon: Icons.trending_up,
          color: Colors.teal,
          onTap: () {
            setState(() => _selectedAction = 'sale');
            _nextStep(ChatStep.partySelection);
          },
        ),
        _futuristicChoiceButton(
          label: 'Record a Purchase',
          icon: Icons.trending_down,
          color: Colors.orange,
          onTap: () {
            setState(() => _selectedAction = 'purchase');
            _nextStep(ChatStep.partySelection);
          },
        ),
        _futuristicChoiceButton(
          label: 'Record a Payment',
          icon: Icons.payments,
          color: Colors.blue,
          onTap: () {
            setState(() => _selectedAction = 'payment');
            _nextStep(ChatStep.partySelection);
          },
        ),
      ],
    );
  }

  Widget _buildPartyChoices() {
    final partiesByType = ref.watch(
      partiesProvider(_selectedAction == 'purchase' ? 'supplier' : 'customer'),
    );

    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search or type name...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          child: partiesByType.when(
            data: (parties) {
              final filtered = parties
                  .where(
                    (p) => p.name.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ),
                  )
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    return _partyTile(
                      'Create "${_searchController.text}"',
                      'Tap to create new party',
                      Icons.person_add,
                      true,
                      () => _createAndSelectParty(_searchController.text),
                    );
                  }
                  final party = filtered[index];
                  return _partyTile(
                    party.name,
                    party.phoneNumber ?? 'No contact',
                    Icons.person,
                    false,
                    () {
                      setState(() => _selectedParty = party);
                      _nextStep(ChatStep.transactionDetails);
                    },
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, s) => Text('Error: $e'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _selectedAction = null;
            _step = ChatStep.actionSelection;
          }),
          child: const Text('Back to Start'),
        ),
      ],
    );
  }

  Widget _partyTile(
    String title,
    String subtitle,
    IconData icon,
    bool isAction,
    VoidCallback onTap,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isAction
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                radius: 18,
                child: Icon(
                  icon,
                  size: 18,
                  color: isAction
                      ? Colors.blue
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionInput() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
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
                  maxLines: 2,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Describe details...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _processPrompt,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _nextStep(ChatStep.partySelection),
          child: const Text('Change Party'),
        ),
      ],
    );
  }

  Widget _buildReviewCard() {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final data = _extractedData!;

    return Column(
      children: [
        Card(
          elevation: 0,
          color: Colors.blue.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.blue.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedAction == 'sale'
                            ? Icons.trending_up
                            : (_selectedAction == 'purchase'
                                  ? Icons.trending_down
                                  : Icons.payments),
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedParty?.name ??
                                data['partyName'] ??
                                'No Party',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            _selectedAction == 'sale'
                                ? 'SALES ENTRY'
                                : (_selectedAction == 'purchase'
                                      ? 'PURCHASE ENTRY'
                                      : 'PAYMENT ENTRY'),
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                _reviewItem(
                  Icons.currency_rupee,
                  'Amount',
                  fmt.format(data['totalAmount']),
                  true,
                ),
                if (_selectedAction == 'payment') ...[
                  _reviewItem(
                    Icons.category,
                    'Type',
                    data['paymentType'] == 'receipt'
                        ? 'Receipt (In)'
                        : 'Payment (Out)',
                    false,
                  ),
                  _reviewItem(
                    Icons.account_balance_wallet,
                    'Method',
                    data['paymentMethod'].toString().toUpperCase(),
                    false,
                  ),
                ] else ...[
                  if (data['invoiceNumber'] != null)
                    _reviewItem(
                      Icons.numbers,
                      'Inv #',
                      data['invoiceNumber'],
                      false,
                    ),
                  if (data['notes'] != null)
                    _reviewItem(Icons.notes, 'Notes', data['notes'], false),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _confirmAndRecord,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ),
          child: const Text(
            'Confirm and Record',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _extractedData = null;
            _step = ChatStep.transactionDetails;
          }),
          child: const Text('Edit Details'),
        ),
      ],
    );
  }

  Widget _reviewItem(
    IconData icon,
    String label,
    String value,
    bool highlight,
  ) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.4,
              ),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: highlight ? 18 : 14,
                color: highlight
                    ? Colors.blue
                    : (isDark ? Colors.white : Colors.black),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _futuristicChoiceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAndSelectParty(String name) async {
    if (name.trim().isEmpty) return;

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) {
      setState(() => _error = 'User not authenticated');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(partyRepositoryProvider);
      final newParty = Party(
        id: '',
        userId: userId,
        partyType: _selectedAction == 'purchase' ? 'supplier' : 'customer',
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await repo.createParty(newParty);
      _selectedParty = Party(
        id: id,
        userId: userId,
        name: name,
        partyType: newParty.partyType,
        createdAt: newParty.createdAt,
        updatedAt: newParty.updatedAt,
      );
      _nextStep(ChatStep.transactionDetails);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
