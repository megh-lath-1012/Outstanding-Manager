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

enum ChatStep {
  actionSelection,
  partySelection,
  transactionDetails,
  review,
}

class PaymentAssistantDialog extends ConsumerStatefulWidget {
  const PaymentAssistantDialog({super.key});

  @override
  ConsumerState<PaymentAssistantDialog> createState() =>
      _PaymentAssistantDialogState();
}

class _PaymentAssistantDialogState
    extends ConsumerState<PaymentAssistantDialog> {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  
  ChatStep _step = ChatStep.actionSelection;
  String? _selectedAction; // 'sale', 'purchase', 'payment'
  Party? _selectedParty;
  bool _isLoading = false;
  Map<String, dynamic>? _extractedData;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _nextStep(ChatStep next) {
    setState(() {
      _step = next;
      _error = null;
    });
  }

  Future<void> _processPrompt() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assistant = ref.read(paymentAssistantServiceProvider);
      
      if (_selectedAction == 'payment') {
        _extractedData = await assistant.processPaymentPrompt(_controller.text.trim());
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
            content: Text(
              '${_selectedAction![0].toUpperCase()}${_selectedAction!.substring(1)} recorded successfully.',
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
            .map((a) => PaymentAllocation(
                  invoiceId: a['invoiceId'],
                  invoiceNumber: a['invoiceNumber'],
                  allocatedAmount: (a['allocatedAmount'] as num).toDouble(),
                ))
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
      invoiceNumber: _extractedData!['invoiceNumber'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      docType: 'Invoice/Bill',
      invoiceDate: _extractedData!['date'] != null ? DateTime.parse(_extractedData!['date']) : DateTime.now(),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case ChatStep.actionSelection:
        return _buildActionSelection();
      case ChatStep.partySelection:
        return _buildPartySelection();
      case ChatStep.transactionDetails:
        return _buildTransactionDetails();
      case ChatStep.review:
        return _buildReview();
    }
  }

  Widget _buildActionSelection() {
    return Column(
      key: const ValueKey('actionSelection'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('How can I help you today?'),
        const SizedBox(height: 20),
        _actionButton(
          label: 'Record a Sale',
          icon: Icons.trending_up,
          color: Colors.green,
          onTap: () {
            _selectedAction = 'sale';
            _nextStep(ChatStep.partySelection);
          },
        ),
        _actionButton(
          label: 'Record a Purchase',
          icon: Icons.trending_down,
          color: Colors.orange,
          onTap: () {
            _selectedAction = 'purchase';
            _nextStep(ChatStep.partySelection);
          },
        ),
        _actionButton(
          label: 'Record a Payment',
          icon: Icons.payments,
          color: Colors.blue,
          onTap: () {
            _selectedAction = 'payment';
            _nextStep(ChatStep.partySelection);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPartySelection() {
    final partiesByType = ref.watch(partiesProvider(_selectedAction == 'purchase' ? 'supplier' : 'customer'));
    
    return Column(
      key: const ValueKey('partySelection'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Who is the ${_selectedAction == 'purchase' ? 'supplier' : 'customer'}?'),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search or type name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: partiesByType.when(
            data: (parties) {
              final filtered = parties.where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.add)),
                      title: Text('Create "${_searchController.text}" as new party'),
                      onTap: () => _createAndSelectParty(_searchController.text),
                    );
                  }
                  final party = filtered[index];
                  return ListTile(
                    title: Text(party.name),
                    subtitle: Text(party.phoneNumber ?? ''),
                    onTap: () {
                      _selectedParty = party;
                      _nextStep(ChatStep.transactionDetails);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _nextStep(ChatStep.actionSelection),
          child: const Text('Back'),
        ),
        const SizedBox(height: 24),
      ],
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

  Widget _buildTransactionDetails() {
    return Column(
      key: const ValueKey('transactionDetails'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Details for ${_selectedParty?.name}'),
        const SizedBox(height: 8),
        Text(
          _selectedAction == 'payment'
              ? 'Tell me about the payment. E.g., "Received ₹500 via UPI"'
              : 'Describe the $_selectedAction details. E.g., "Sold 10 packets of milk for ₹500"',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Type transaction details...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: _processPrompt,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Analyze with AI'),
          ),
        TextButton(
          onPressed: () => _nextStep(ChatStep.partySelection),
          child: const Text('Back'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReview() {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return Column(
      key: const ValueKey('review'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('Confirm Entry'),
        const SizedBox(height: 16),
        _buildResultCard(context, fmt),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: _confirmAndRecord,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm and Save'),
          ),
        TextButton(
          onPressed: () => _nextStep(ChatStep.transactionDetails),
          child: const Text('Edit Details'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _header(String title) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, NumberFormat fmt) {
    final data = _extractedData!;
    
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedParty?.name ?? data['partyName'] ?? 'No Party',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  fmt.format(data['totalAmount']),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            if (_selectedAction == 'payment') ...[
              Text('Type: ${data['paymentType'] == 'receipt' ? 'Receipt (In)' : 'Payment (Out)'}'),
              Text('Method: ${data['paymentMethod'].toString().toUpperCase()}'),
              const SizedBox(height: 8),
              if (data['allocations'] != null) ...[
                const Text('Allocations (FIFO):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ...(data['allocations'] as List).map((a) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Inv #${a['invoiceNumber']}', style: const TextStyle(fontSize: 11)),
                      Text(fmt.format(a['allocatedAmount']), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                )),
              ],
            ] else ...[
              Text('Action: ${_selectedAction == 'sale' ? 'Sale' : 'Purchase'}'),
              if (data['invoiceNumber'] != null) Text('Inv #: ${data['invoiceNumber']}'),
              if (data['notes'] != null) Text('Notes: ${data['notes']}'),
            ],
          ],
        ),
      ),
    );
  }
}
