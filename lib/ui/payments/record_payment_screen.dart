import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/payment_model.dart';

/// Smart Payment Recording Screen
/// - Auto-distributes payment across oldest bills first
/// - Or manually choose amounts per bill
class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String invoiceType; // 'sales' or 'purchase'
  final Invoice? initialInvoice;
  final String? partyId;
  final String? partyName;

  const RecordPaymentScreen({
    super.key,
    required this.invoiceType,
    this.initialInvoice,
    this.partyId,
    this.partyName,
  });

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );

  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  bool _autoDistribute = true;

  // Invoice allocations: invoiceId -> controller
  final Map<String, _AllocEntry> _allocations = {};
  List<Invoice> _availableInvoices = [];

  String get _paymentType =>
      widget.invoiceType == 'sales' ? 'receipt' : 'payment';
  String get _screenTitle =>
      widget.invoiceType == 'sales' ? 'Record Receipt' : 'Record Payment';
  String get _partyLabel =>
      widget.invoiceType == 'sales' ? 'Customer' : 'Supplier';

  String? get _effectivePartyId =>
      widget.initialInvoice?.partyId ?? widget.partyId;
  String? get _effectivePartyName =>
      widget.initialInvoice?.partyName ?? widget.partyName;

  static const List<String> _methods = [
    'cash',
    'bank_transfer',
    'upi',
    'cheque',
    'card',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoice != null) {
      final inv = widget.initialInvoice!;
      _allocations[inv.id] = _AllocEntry(
        invoice: inv,
        controller: TextEditingController(
          text: inv.outstandingAmount.toStringAsFixed(2),
        ),
      );
      _amountController.text = inv.outstandingAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    for (var e in _allocations.values) {
      e.controller.dispose();
    }
    super.dispose();
  }

  void _autoDistributeAmount() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    if (totalAmount <= 0) return;

    // Clear existing
    for (var e in _allocations.values) {
      e.controller.dispose();
    }
    _allocations.clear();

    // Sort available invoices by date (oldest first)
    final sortedInvoices = List<Invoice>.from(_availableInvoices)
      ..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));

    double remaining = totalAmount;
    for (var inv in sortedInvoices) {
      if (remaining <= 0.01) break;
      if (inv.outstandingAmount <= 0) continue;

      final allocAmount = remaining >= inv.outstandingAmount
          ? inv.outstandingAmount
          : remaining;
      _allocations[inv.id] = _AllocEntry(
        invoice: inv,
        controller: TextEditingController(text: allocAmount.toStringAsFixed(2)),
      );
      remaining -= allocAmount;
    }

    setState(() {});
  }

  double get _totalAllocated {
    double total = 0;
    for (var e in _allocations.values) {
      total += double.tryParse(e.controller.text) ?? 0;
    }
    return total;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_allocations.isEmpty) {
      _showError('No invoices to allocate. Enter an amount first.');
      return;
    }

    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    final List<PaymentAllocation> finalAllocs = [];

    for (var e in _allocations.entries) {
      final amt = double.tryParse(e.value.controller.text) ?? 0;
      if (amt <= 0) continue;
      if (amt > e.value.invoice.outstandingAmount + 0.01) {
        _showError(
          'Amount for ${e.value.invoice.invoiceNumber} exceeds outstanding.',
        );
        return;
      }
      finalAllocs.add(
        PaymentAllocation(
          invoiceId: e.key,
          invoiceNumber: e.value.invoice.invoiceNumber,
          allocatedAmount: amt,
        ),
      );
    }

    if (finalAllocs.isEmpty) {
      _showError('Please allocate amounts to at least one invoice.');
      return;
    }

    final totalAlloc = finalAllocs.fold(0.0, (s, a) => s + a.allocatedAmount);
    if ((totalAmount - totalAlloc).abs() > 0.01) {
      _showError(
        'Total allocated (\u20b9${totalAlloc.toStringAsFixed(2)}) must equal total amount (\u20b9${totalAmount.toStringAsFixed(2)}).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payment = Payment(
        id: '',
        partyId: _effectivePartyId!,
        partyName: _effectivePartyName!,
        paymentType: _paymentType,
        paymentDate: _paymentDate,
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(paymentRepositoryProvider)
          .recordPayment(payment, finalAllocs);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$_screenTitle saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    // Load available invoices for this party
    if (_effectivePartyId != null) {
      final query = InvoiceQuery(
        invoiceType: widget.invoiceType,
        partyId: _effectivePartyId!,
      );
      final invoicesAsync = ref.watch(invoicesProvider(query));
      invoicesAsync.whenData((invoices) {
        _availableInvoices = invoices
            .where((i) => i.outstandingAmount > 0)
            .toList();
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Party info (read-only)
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: _partyLabel,
                        prefixIcon: const Icon(Icons.person),
                      ),
                      child: Text(
                        _effectivePartyName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date + Method
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _paymentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() => _paymentDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date *',
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_paymentDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Method *',
                            ),
                            initialValue: _paymentMethod,
                            isExpanded: true,
                            items: _methods
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _paymentMethod = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Reference
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference Number',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'Cheque no. / UTR / Txn ID',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total Amount *',
                        prefixText: '\u20b9 ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }
                        if ((double.tryParse(v) ?? 0) <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        if (_autoDistribute) _autoDistributeAmount();
                      },
                    ),
                    const SizedBox(height: 20),

                    // Distribution mode toggle
                    const Divider(),
                    SwitchListTile(
                      title: const Text(
                        'Auto-distribute (oldest bills first)',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: _autoDistribute,
                      onChanged: (val) {
                        setState(() => _autoDistribute = val);
                        if (val) _autoDistributeAmount();
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    Text(
                      'ALLOCATION',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Allocation cards
                    if (_allocations.isEmpty && _availableInvoices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'No outstanding invoices for this party.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),

                    ..._allocations.entries.map(
                      (e) => _buildAllocCard(e.key, e.value),
                    ),

                    if (!_autoDistribute &&
                        _availableInvoices.any(
                          (inv) => !_allocations.containsKey(inv.id),
                        ))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _showAddInvoiceSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Invoice'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Summary bar
                    _buildSummaryBar(),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: const Icon(Icons.check_circle),
                        label: Text(_screenTitle),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAllocCard(String invoiceId, _AllocEntry entry) {
    final inv = entry.invoice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (!_autoDistribute)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        entry.controller.dispose();
                        _allocations.remove(invoiceId);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('dd MMM yyyy').format(inv.invoiceDate)} • Due: ${currencyFormat.format(inv.outstandingAmount)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_autoDistribute,
              decoration: const InputDecoration(
                labelText: 'Allocate',
                prefixText: '\u20b9 ',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInvoiceSheet() {
    final available = _availableInvoices
        .where((inv) => !_allocations.containsKey(inv.id))
        .toList();
    if (available.isEmpty) {
      _showError('No more unpaid invoices available.');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Invoice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...available.map(
              (inv) => ListTile(
                title: Text(
                  inv.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Due: ${currencyFormat.format(inv.outstandingAmount)} • ${DateFormat('dd MMM').format(inv.invoiceDate)}',
                ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  setState(() {
                    _allocations[inv.id] = _AllocEntry(
                      invoice: inv,
                      controller: TextEditingController(
                        text: inv.outstandingAmount.toStringAsFixed(2),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final allocated = _totalAllocated;
    final total = double.tryParse(_amountController.text) ?? 0;
    final remaining = total - allocated;
    final isBalanced = remaining.abs() < 0.01 && _allocations.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isBalanced
            ? Colors.green.withAlpha(20)
            : Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBalanced ? Colors.green : Colors.orange),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allocated: ${currencyFormat.format(allocated)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Remaining: ${currencyFormat.format(remaining)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
          ),
          Icon(
            isBalanced ? Icons.check_circle : Icons.warning_amber,
            color: isBalanced ? Colors.green : Colors.orange,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _AllocEntry {
  final Invoice invoice;
  final TextEditingController controller;
  _AllocEntry({required this.invoice, required this.controller});
}
