import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/party_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/party_model.dart';

class AddPartyScreen extends ConsumerStatefulWidget {
  final String initialType;
  final Party? partyToEdit;

  const AddPartyScreen({
    super.key,
    required this.initialType,
    this.partyToEdit,
  });

  @override
  ConsumerState<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends ConsumerState<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _partyType;
  
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _balanceController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _partyType = widget.partyToEdit?.partyType ?? widget.initialType;
    
    if (widget.partyToEdit != null) {
      final p = widget.partyToEdit!;
      _nameController.text = p.name;
      _contactController.text = p.contactPerson ?? '';
      _phoneController.text = p.phoneNumber ?? '';
      _emailController.text = p.email ?? '';
      _addressController.text = p.address ?? '';
      _gstController.text = p.gstNumber ?? '';
      _balanceController.text = p.openingBalance.toString();
    } else {
      _balanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception("User not authenticated");

      final partyData = Party(
        id: widget.partyToEdit?.id ?? '', // Handled by repository on create
        userId: user.uid,
        partyType: _partyType,
        name: _nameController.text.trim(),
        contactPerson: _contactController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim(),
        openingBalance: double.tryParse(_balanceController.text) ?? 0.0,
        createdAt: widget.partyToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.partyToEdit == null) {
        await ref.read(partyRepositoryProvider).createParty(partyData);
      } else {
        await ref.read(partyRepositoryProvider).updateParty(widget.partyToEdit!.id, partyData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Party saved successfully!')),
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
    final isEditing = widget.partyToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Party' : 'New Party'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Selection
                    if (!isEditing) ...[
                      const Text('Party Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Customer'),
                              value: 'customer',
                              groupValue: _partyType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _partyType = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Supplier'),
                              value: 'supplier',
                              groupValue: _partyType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _partyType = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Party or Business Name *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Person Name'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email Address'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _gstController,
                      decoration: const InputDecoration(labelText: 'GST / Tax Number'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                         labelText: 'Opening Balance',
                         prefixText: '₹ ',
                         helperText: 'Positive = To Collect, Negative = To Pay',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Billing Address'),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        child: const Text('SAVE PARTY'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
