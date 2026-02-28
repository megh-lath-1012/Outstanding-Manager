import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/party_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/payment_model.dart';
import '../../models/party_model.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String paymentType;

  const AddPaymentScreen({super.key, required this.paymentType});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Party? _selectedParty;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';
  
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'cash', 'bank_transfer', 'upi', 'cheque', 'card', 'other'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
     if (!_formKey.currentState!.validate()) return;
     if (_selectedParty == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a party')));
       return;
     }

     setState(() => _isLoading = true);

     try {
       final user = ref.read(authStateProvider).value;
       if (user == null) throw Exception("Not authenticated");

       final payment = Payment(
         id: '',
         userId: user.uid,
         partyId: _selectedParty!.id,
         partyName: _selectedParty!.name,
         paymentType: widget.paymentType,
         paymentDate: _paymentDate,
         totalAmount: double.parse(_amountController.text),
         paymentMethod: _paymentMethod,
         referenceNumber: _referenceController.text,
         notes: _notesController.text,
         createdAt: DateTime.now(),
         updatedAt: DateTime.now(),
       );

       // Note: In this mockup we are bypassing actual invoice allocation selection
       // and just saving an unallocated payment for the sake of simplicity.
       // In the full spec, there is a complex UI step here to select unpaid invoices
       // to allocate this payment to.
       await ref.read(paymentRepositoryProvider).recordPayment(payment, []);

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Payment recorded successfully')),
         );
         Navigator.of(context).pop();
       }
     } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
     } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final partyType = widget.paymentType == 'receipt' ? 'customer' : 'supplier';
    final partiesAsync = ref.watch(partiesProvider(partyType));
    
    final typeLabel = widget.paymentType == 'receipt' ? 'Payment In (Receipt)' : 'Payment Out';

    return Scaffold(
      appBar: AppBar(
         title: Text('Record $typeLabel'),
         actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: (_isLoading || partiesAsync.isLoading) ? null : _save,
            )
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
                      // 1. Party Selection
                      partiesAsync.when(
                        data: (parties) {
                          return DropdownButtonFormField<Party>(
                            decoration: InputDecoration(
                              labelText: 'Received From *',
                              prefixIcon: Icon(widget.paymentType == 'receipt' ? Icons.download : Icons.upload),
                            ),
                            value: _selectedParty,
                            items: parties.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                            onChanged: (val) => setState(() => _selectedParty = val),
                            validator: (v) => v == null ? 'Please select a party' : null,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e,s) => Text('Error: $e'),
                      ),
                      const SizedBox(height: 24),

                      // 2. Amount and Date
                      Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Expanded(
                               flex: 3,
                               child: TextFormField(
                                 controller: _amountController,
                                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                 maxLength: 10,
                                 decoration: const InputDecoration(
                                    labelText: 'Total Amount *',
                                    prefixText: '₹ ',
                                    counterText: '',
                                 ),
                                 validator: (v) {
                                   if (v == null || v.isEmpty) return 'Required';
                                   if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid';
                                   return null;
                                 },
                               ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                               flex: 2,
                               child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                       context: context,
                                       initialDate: _paymentDate,
                                       firstDate: DateTime(2000),
                                       lastDate: DateTime(2100),
                                    );
                                    if (date != null) setState(() => _paymentDate = date);
                                  },
                                  child: InputDecorator(
                                     decoration: const InputDecoration(labelText: 'Date', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                                     child: Text(DateFormat('dd/MM/yyyy').format(_paymentDate), textAlign: TextAlign.center),
                                  ),
                               ),
                            ),
                         ],
                      ),
                      const SizedBox(height: 24),

                      // 3. Payment Method
                      DropdownButtonFormField<String>(
                         decoration: const InputDecoration(
                           labelText: 'Payment Mode',
                           prefixIcon: Icon(Icons.account_balance_wallet),
                         ),
                         value: _paymentMethod,
                         items: _paymentMethods.map((m) => DropdownMenuItem(
                           value: m, 
                           child: Text(m.replaceAll('_', ' ').toUpperCase()),
                         )).toList(),
                         onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                         controller: _referenceController,
                         decoration: const InputDecoration(
                           labelText: 'Reference Number',
                           hintText: 'Cheque no. / UTR / Txn ID',
                           prefixIcon: Icon(Icons.tag),
                         ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                         controller: _notesController,
                         maxLines: 3,
                         decoration: const InputDecoration(
                           labelText: 'Notes',
                           alignLabelWithHint: true,
                         ),
                      ),
                      const SizedBox(height: 32),

                      /* 
                      Note: Real implementation would query `invoicesProvider` for this party 
                      where status is not 'paid', and list them here with checkboxes and
                      textfields to allocate the `_amountController.text` across them.
                      */
                      Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.blue.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.blue.withOpacity(0.3)),
                         ),
                         child: const Row(
                           children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Invoice allocation feature requires connecting to Firestore and fetching unpaid invoices for the selected party.', style: TextStyle(color: Colors.blue)),
                              ),
                           ],
                         ),
                      ),
                   ],
                ),
             )
         ),
    );
  }
}
