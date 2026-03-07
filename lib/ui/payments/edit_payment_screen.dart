import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';

class EditPaymentScreen extends ConsumerStatefulWidget {
  final Payment payment;

  const EditPaymentScreen({super.key, required this.payment});

  @override
  ConsumerState<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends ConsumerState<EditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _referenceController;

  late DateTime _paymentDate;
  late String _paymentMethod;
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20b9',
  );

  @override
  void initState() {
    super.initState();
    _paymentDate = widget.payment.paymentDate;
    _paymentMethod = widget.payment.paymentMethod;
    _notesController = TextEditingController(text: widget.payment.notes ?? '');
    _referenceController = TextEditingController(
      text: widget.payment.referenceNumber ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedPayment = widget.payment.copyWith(
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        referenceNumber: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
      );

      await ref
          .read(paymentRepositoryProvider)
          .updatePaymentBasic(widget.payment.id, updatedPayment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment details updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Payment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Non-editable amount and party
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Party: ${widget.payment.partyName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Amount: ${currencyFormat.format(widget.payment.totalAmount)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Financial amounts cannot be changed directly to preserve invoice allocations.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Editable Fields
                    InkWell(
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
                          labelText: 'Payment Date',
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_paymentDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Builder(
                      builder: (context) {
                        final methods = [
                          'cash',
                          'bank_transfer',
                          'upi',
                          'cheque',
                          'card',
                          'other',
                        ];
                        if (!methods.contains(_paymentMethod)) {
                          methods.add(_paymentMethod);
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet,
                              size: 18,
                            ),
                          ),
                          items: methods
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    m.replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _paymentMethod = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference Number (optional)',
                        prefixIcon: Icon(Icons.receipt, size: 18),
                        helperText: 'Cheque No, UTR, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
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
}
