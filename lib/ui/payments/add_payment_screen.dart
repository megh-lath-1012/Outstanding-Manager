import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/party_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../models/payment_model.dart';
import '../../models/invoice_model.dart';
import '../../models/party_model.dart';
import '../parties/add_party_screen.dart';

/// Payment Recording Screen — supports 3 entry flows:
/// 1. From Invoice detail (initialInvoice set)
/// 2. From Party detail  (initialParty set)
/// 3. From Payments tab   (nothing pre-filled)
class AddPaymentScreen extends ConsumerStatefulWidget {
  /// Optional: pre-select a specific invoice (Flow 1)
  final Invoice? initialInvoice;

  /// Optional: pre-select a party (Flow 2)
  final Party? initialParty;

  /// Legacy compat — if set, overrides auto-detection
  final String? paymentType;

  const AddPaymentScreen({
    super.key,
    this.initialInvoice,
    this.initialParty,
    this.paymentType,
  });

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  Party? _selectedParty;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  bool _partyLocked = false; // When navigated from invoice/party

  /// Map of invoiceId -> allocation details
  final Map<String, _InvoiceAllocationEntry> _allocations = {};

  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );

  static const List<String> _paymentMethods = [
    'cash',
    'bank_transfer',
    'upi',
    'cheque',
    'card',
    'other',
  ];

  /// Derived from selected party's type
  String get _derivedPaymentType {
    if (widget.paymentType != null) return widget.paymentType!;
    if (_selectedParty == null) return 'receipt';
    return _selectedParty!.partyType == 'customer' ? 'receipt' : 'payment';
  }

  String get _invoiceType {
    return _derivedPaymentType == 'receipt' ? 'sales' : 'purchase';
  }

  String get _partyFilterType {
    if (widget.paymentType != null) {
      return widget.paymentType == 'receipt' ? 'customer' : 'supplier';
    }
    return _selectedParty?.partyType ?? 'customer';
  }

  @override
  void initState() {
    super.initState();

    // Flow 1: Pre-fill from a specific invoice
    if (widget.initialInvoice != null) {
      final inv = widget.initialInvoice!;
      _selectedParty = Party(
        id: inv.partyId,
        userId: '',
        partyType: inv.invoiceType == 'sales' ? 'customer' : 'supplier',
        name: inv.partyName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _partyLocked = true;
      if (inv.outstandingAmount > 0) {
        _allocations[inv.id] = _InvoiceAllocationEntry(
          invoice: inv,
          controller: TextEditingController(
            text: inv.outstandingAmount.toString(),
          ),
        );
        _recalculateTotal();
      }
    }
    // Flow 2: Pre-fill from a specific party
    else if (widget.initialParty != null) {
      _selectedParty = widget.initialParty;
      _partyLocked = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    for (var entry in _allocations.values) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  void _recalculateTotal() {
    double total = 0;
    for (var entry in _allocations.values) {
      total += double.tryParse(entry.controller.text) ?? 0;
    }
    _amountController.text = total.toStringAsFixed(2);
  }

  double get _totalAllocated {
    double total = 0;
    for (var entry in _allocations.values) {
      total += double.tryParse(entry.controller.text) ?? 0;
    }
    return total;
  }

  double get _totalPayment => double.tryParse(_amountController.text) ?? 0;
  double get _remaining => _totalPayment - _totalAllocated;

  // ─── SAVE ───
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParty == null) {
      _showError('Please select a party');
      return;
    }
    if (_allocations.isEmpty) {
      _showError('Please select at least one invoice to allocate.');
      return;
    }

    // Build allocations list
    final List<PaymentAllocation> finalAllocations = [];
    for (var entry in _allocations.entries) {
      final amt = double.tryParse(entry.value.controller.text) ?? 0;
      if (amt <= 0) {
        _showError(
          'Allocated amount for ${entry.value.invoice.invoiceNumber} must be > 0.',
        );
        return;
      }
      if (amt > entry.value.invoice.outstandingAmount + 0.01) {
        _showError(
          'Allocated amount for ${entry.value.invoice.invoiceNumber} exceeds outstanding (\u20b9${entry.value.invoice.outstandingAmount}).',
        );
        return;
      }
      finalAllocations.add(
        PaymentAllocation(
          invoiceId: entry.key,
          invoiceNumber: entry.value.invoice.invoiceNumber,
          allocatedAmount: amt,
        ),
      );
    }

    // Rule 1: total allocated must equal total payment
    final totalAlloc = finalAllocations.fold(
      0.0,
      (s, a) => s + a.allocatedAmount,
    );
    if ((_totalPayment - totalAlloc).abs() > 0.01) {
      _showError(
        'Total Allocated (\u20b9${totalAlloc.toStringAsFixed(2)}) must equal Total Payment (\u20b9${_totalPayment.toStringAsFixed(2)}).',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception("Not authenticated");

      final payment = Payment(
        id: '',
        partyId: _selectedParty!.id,
        partyName: _selectedParty!.name,
        paymentType: _derivedPaymentType,
        paymentDate: _paymentDate,
        totalAmount: _totalPayment,
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
          .recordPayment(payment, finalAllocations);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_derivedPaymentType == 'receipt' ? 'Receipt' : 'Payment'} recorded successfully!',
            ),
          ),
        );
        Navigator.of(context).pop();
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

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final typeLabel = _derivedPaymentType == 'receipt'
        ? 'Record Receipt'
        : 'Record Payment';
    final partyType = _partyFilterType;
    final partiesAsync = ref.watch(partiesProvider(partyType));

    return Scaffold(
      appBar: AppBar(
        title: Text(typeLabel),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Party Selection ──
                    _buildPartySelector(partiesAsync, partyType),
                    const SizedBox(height: 20),

                    // ── 2. Date & Method Row ──
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
                              if (date != null)
                                setState(() => _paymentDate = date);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Payment Date *',
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
                              prefixIcon: Icon(
                                Icons.account_balance_wallet,
                                size: 18,
                              ),
                            ),
                            value: _paymentMethod,
                            items: _paymentMethods
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      m.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _paymentMethod = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Reference Number ──
                    TextFormField(
                      controller: _referenceController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Reference Number',
                        hintText: 'Cheque no. / UTR / Txn ID',
                        prefixIcon: Icon(Icons.tag),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 4. Total Payment Amount (prominent) ──
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
                        labelText: 'Total Payment Amount *',
                        prefixText: '\u20b9 ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // ── 5. Invoice Allocation Section ──
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'ALLOCATE TO INVOICES',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedParty != null) ...[
                      // Render each allocation card
                      ..._allocations.entries.map(
                        (e) => _buildAllocationCard(e.key, e.value),
                      ),
                      const SizedBox(height: 8),

                      // "+ Add Another Invoice" button
                      OutlinedButton.icon(
                        onPressed: () => _showAddInvoiceSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Invoice'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 6. Allocation Summary Bar ──
                      _buildAllocationSummary(),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'Select a ${_partyFilterType == 'customer' ? 'customer' : 'supplier'} to see unpaid invoices.',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── 7. Notes ──
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button at bottom too
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          _derivedPaymentType == 'receipt'
                              ? 'Record Receipt'
                              : 'Record Payment',
                        ),
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

  // ─── PARTY SELECTOR ───
  Widget _buildPartySelector(
    AsyncValue<List<Party>> partiesAsync,
    String partyType,
  ) {
    if (_partyLocked && _selectedParty != null) {
      // Show locked/read-only card
      return InputDecorator(
        decoration: InputDecoration(
          labelText: partyType == 'customer' ? 'Customer' : 'Supplier',
          prefixIcon: Icon(
            _derivedPaymentType == 'receipt' ? Icons.download : Icons.upload,
          ),
        ),
        child: Text(
          _selectedParty!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return partiesAsync.when(
      data: (parties) {
        return FormField<Party>(
          validator: (_) =>
              _selectedParty == null ? 'Please select a party' : null,
          builder: (state) {
            return InkWell(
              onTap: () => _showPartySheet(context, parties, partyType, state),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      '${partyType == 'customer' ? 'Received From' : 'Paid To'} *',
                  prefixIcon: Icon(
                    _derivedPaymentType == 'receipt'
                        ? Icons.download
                        : Icons.upload,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: state.errorText,
                ),
                child: Text(
                  _selectedParty?.name ?? 'Choose...',
                  style: TextStyle(
                    color: _selectedParty == null ? Colors.grey.shade600 : null,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  void _showPartySheet(
    BuildContext context,
    List<Party> parties,
    String partyType,
    FormFieldState<Party> state,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = parties
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select ${partyType == 'customer' ? 'Customer' : 'Supplier'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        onChanged: (val) =>
                            setModalState(() => searchQuery = val),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: Text(
                        'Add New ${partyType == 'customer' ? 'Customer' : 'Supplier'}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AddPartyScreen(initialType: partyType),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(25),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: p.phoneNumber != null
                                ? Text(p.phoneNumber!)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedParty = p;
                                _allocations
                                    .clear(); // Reset allocations on party change
                                _amountController.clear();
                              });
                              state.didChange(p);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── ALLOCATION CARD ───
  Widget _buildAllocationCard(String invoiceId, _InvoiceAllocationEntry entry) {
    final inv = entry.invoice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      entry.controller.dispose();
                      _allocations.remove(invoiceId);
                      _recalculateTotal();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Info row
            Text(
              'Date: ${DateFormat('dd MMM yyyy').format(inv.invoiceDate)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Total: ${currencyFormat.format(inv.totalAmount)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Due: ${currencyFormat.format(inv.outstandingAmount)}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Allocation amount input
            TextFormField(
              controller: entry.controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Allocate',
                prefixText: '\u20b9 ',
                isDense: true,
              ),
              onChanged: (_) => setState(() => _recalculateTotal()),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD INVOICE BOTTOM SHEET ───
  void _showAddInvoiceSheet(BuildContext context) {
    if (_selectedParty == null) return;

    final query = InvoiceQuery(
      invoiceType: _invoiceType,
      partyId: _selectedParty!.id,
    );
    final invoicesAsync = ref.read(invoicesProvider(query));

    invoicesAsync.when(
      data: (invoices) {
        final available = invoices
            .where(
              (i) => i.outstandingAmount > 0 && !_allocations.containsKey(i.id),
            )
            .toList();

        if (available.isEmpty) {
          _showError('No more unpaid invoices available for this party.');
          return;
        }

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return SafeArea(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                          _allocations[inv.id] = _InvoiceAllocationEntry(
                            invoice: inv,
                            controller: TextEditingController(
                              text: inv.outstandingAmount.toString(),
                            ),
                          );
                          _recalculateTotal();
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      loading: () => _showError('Loading invoices...'),
      error: (e, _) => _showError('Error: $e'),
    );
  }

  // ─── ALLOCATION SUMMARY BAR ───
  Widget _buildAllocationSummary() {
    final allocated = _totalAllocated;
    final isBalanced = _remaining.abs() < 0.01 && _allocations.isNotEmpty;

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
                'Total Allocated: ${currencyFormat.format(allocated)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Remaining: ${currencyFormat.format(_remaining)}',
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

/// Internal helper to hold per-invoice allocation state
class _InvoiceAllocationEntry {
  final Invoice invoice;
  final TextEditingController controller;

  _InvoiceAllocationEntry({required this.invoice, required this.controller});
}
