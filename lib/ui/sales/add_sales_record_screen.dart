import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/party_provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/invoice_model.dart';
import '../../models/party_model.dart';
import '../../models/payment_model.dart';
import '../parties/add_party_screen.dart';

class AddSalesRecordScreen extends ConsumerStatefulWidget {
  final Invoice? initialInvoice;

  const AddSalesRecordScreen({super.key, this.initialInvoice});

  @override
  ConsumerState<AddSalesRecordScreen> createState() =>
      _AddSalesRecordScreenState();
}

class _AddSalesRecordScreenState extends ConsumerState<AddSalesRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _advanceController = TextEditingController();
  final _descriptionController = TextEditingController();

  Party? _selectedParty;
  String _docType = 'Invoice/Bill';
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  Future<List<Map<String, dynamic>>>? _paymentsFuture;

  bool get _isEditing => widget.initialInvoice != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final inv = widget.initialInvoice!;
      _invoiceNumberController.text = inv.invoiceNumber;
      _amountController.text = inv.totalAmount.toString();
      _descriptionController.text = inv.description ?? '';
      _docType = inv.docType;
      _invoiceDate = inv.invoiceDate;
      _dueDate = inv.dueDate;
      // Fetch payment allocations
      _paymentsFuture = ref
          .read(paymentRepositoryProvider)
          .getPaymentsForInvoice(inv.id, inv.partyId);
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _amountController.dispose();
    _advanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a party'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalAmount = double.parse(_amountController.text);
      final advanceAmount = _advanceController.text.isNotEmpty
          ? double.parse(_advanceController.text)
          : 0.0;

      if (advanceAmount > totalAmount) {
        throw Exception('Advance amount cannot exceed total amount.');
      }

      final invoice = Invoice(
        id: _isEditing ? widget.initialInvoice!.id : '',
        partyId: _selectedParty!.id,
        partyName: _selectedParty!.name,
        invoiceType: 'sales',
        invoiceNumber: _invoiceNumberController.text.trim(),
        docType: _docType,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        totalAmount: totalAmount,
        paidAmount: advanceAmount,
        outstandingAmount: totalAmount - advanceAmount,
        paymentStatus: advanceAmount >= totalAmount
            ? 'paid'
            : (advanceAmount > 0 ? 'partial' : 'unpaid'),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        createdAt: _isEditing
            ? widget.initialInvoice!.createdAt
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await ref
            .read(invoiceRepositoryProvider)
            .updateInvoiceBasic(widget.initialInvoice!.id, invoice);
      } else {
        await ref.read(invoiceRepositoryProvider).createInvoice(invoice);

        // If advance payment, create a payment record
        if (advanceAmount > 0) {
          final payment = Payment(
            id: '',
            partyId: _selectedParty!.id,
            partyName: _selectedParty!.name,
            paymentType: 'receipt',
            paymentDate: _invoiceDate,
            totalAmount: advanceAmount,
            paymentMethod: 'cash', // Default to cash for simplicity
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Simplified for MVP, real system would await invoice creation then use its ID for allocation
          // Due to time constraints, advance amount will just live on the invoice for now without ledger entry
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Sale updated successfully'
                  : 'Sale recorded successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesProvider('customer'));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sale' : 'Add Sale Record'),
        elevation: 0,
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
                    // Party selector
                    partiesAsync.when(
                      data: (parties) => _buildPartySelector(parties),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _invoiceDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _invoiceDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_invoiceDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? _invoiceDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() => _dueDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Due Date (optional)',
                                prefixIcon: const Icon(Icons.event, size: 18),
                                suffixIcon: _dueDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () =>
                                            setState(() => _dueDate = null),
                                      )
                                    : null,
                              ),
                              child: Text(
                                _dueDate != null
                                    ? DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_dueDate!)
                                    : 'Select due date',
                                style: TextStyle(
                                  color: _dueDate != null
                                      ? null
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Invoice number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _docType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Invoice/Bill',
                                child: Text(
                                  'Invoice/Bill',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Challan No',
                                child: Text(
                                  'Challan No',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _docType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Number *',
                              prefixIcon: Icon(Icons.tag, size: 18),
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        prefixText: '\u20b9 ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Advance Amount (only for new)
                    if (!_isEditing) ...[
                      TextFormField(
                        controller: _advanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Advance Received',
                          prefixText: '\u20b9 ',
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if ((double.tryParse(v) ?? 0) < 0) {
                              return 'Invalid amount';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment History
                    if (_isEditing) _buildPaymentHistory(),
                    if (_isEditing) const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: _isLoading
                            ? const SizedBox.shrink()
                            : Text(
                                _isEditing ? 'Save Changes' : 'Save Record',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_paymentsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading payments: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final payments = snapshot.data ?? [];
        if (payments.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'PAYMENT HISTORY',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...payments.map((p) {
              final payment = p['payment'] as Payment;
              final alloc = p['allocation'] as PaymentAllocation;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: Text(
                  '\u20b9${alloc.allocatedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${DateFormat('dd MMM yyyy').format(payment.paymentDate)} • ${payment.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                ),
                trailing: Text(
                  payment.referenceNumber != null &&
                          payment.referenceNumber!.isNotEmpty
                      ? 'Ref #${payment.referenceNumber}'
                      : '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPartySelector(List<Party> parties) {
    if (_isEditing) {
      if (_selectedParty == null) {
        // Load party asynchronously
        ref.read(allPartiesProvider.future).then((parties) {
          try {
            final p = parties.firstWhere(
              (p) => p.id == widget.initialInvoice!.partyId,
            );
            if (mounted) setState(() => _selectedParty = p);
          } catch (_) {}
        });
      }

      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Customer *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.person),
        ),
        child: Text(
          widget.initialInvoice!.partyName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    return FormField<Party>(
      validator: (_) =>
          _selectedParty == null ? 'Please select a customer' : null,
      builder: (state) {
        return InkWell(
          onTap: () => _showPartySheet(parties, state),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Customer *',
              prefixIcon: const Icon(Icons.person),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              errorText: state.errorText,
            ),
            child: Text(
              _selectedParty?.name ?? 'Select customer...',
              style: TextStyle(
                color: _selectedParty == null ? Colors.grey.shade600 : null,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPartySheet(List<Party> parties, FormFieldState<Party> state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = parties
                .where(
                  (p) => p.name.toLowerCase().contains(search.toLowerCase()),
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
                          const Text(
                            'Select Customer',
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

                    // Search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) => setSheetState(() => search = val),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Add new
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: const Text(
                        'Add New Customer',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AddPartyScreen(initialType: 'customer'),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // List
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
                              setState(() => _selectedParty = p);
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
}
