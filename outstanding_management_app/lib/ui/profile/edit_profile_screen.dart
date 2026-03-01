import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'gstNumber': _gstController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: userAsync.when(
        data: (user) {
          if (!_initialized && user != null) {
            _nameController.text = user.displayName;
            _phoneController.text = user.phoneNumber ?? '';
            _companyNameController.text = user.companyName ?? '';
            _emailController.text = user.email;
            _addressController.text = user.address ?? '';
            _gstController.text = user.gstNumber ?? '';
            _initialized = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + business name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            (user?.companyName ?? user?.displayName ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Business Details Section
                  Text('BUSINESS DETAILS', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      prefixIcon: Icon(Icons.business),
                      hintText: 'e.g. ABC Enterprises',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Business Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstController,
                    decoration: const InputDecoration(
                      labelText: 'GST Number',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      prefixIcon: Icon(Icons.location_on),
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Personal Details Section
                  Text('PERSONAL DETAILS', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Your Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
