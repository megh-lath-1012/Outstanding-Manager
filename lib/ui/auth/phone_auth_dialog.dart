import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../providers/auth_provider.dart';

class PhoneAuthDialog extends ConsumerStatefulWidget {
  const PhoneAuthDialog({super.key});

  @override
  ConsumerState<PhoneAuthDialog> createState() => _PhoneAuthDialogState();
}

class _PhoneAuthDialogState extends ConsumerState<PhoneAuthDialog> {
  String _phoneNumber = '';
  String _verificationId = '';
  bool _codeSent = false;
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneNumber.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneNumber(
            phoneNumber: _phoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              try {
                await FirebaseAuth.instance.signInWithCredential(credential);
                if (mounted) context.go('/home');
              } catch (e) {
                _showError(e.toString());
                if (mounted) setState(() => _isLoading = false);
              }
            },
            verificationFailed: (FirebaseAuthException e) {
              _showError(e.message ?? 'Verification failed');
              if (mounted) setState(() => _isLoading = false);
            },
            codeSent: (String verificationId, int? resendToken) {
              if (mounted) {
                setState(() {
                  _verificationId = verificationId;
                  _codeSent = true;
                  _isLoading = false;
                });
              }
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              _verificationId = verificationId;
            },
          );
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOTP() async {
    final code = _otpController.text.trim();
    if (code.length != 6) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithSmsCode(_verificationId, code);
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _codeSent ? 'Enter OTP' : 'Phone Sign In',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_codeSent) ...[
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                initialCountryCode:
                    'IN', // Default per initial conversation logic
                onChanged: (phone) {
                  _phoneNumber = phone.completeNumber;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Code'),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: '6-digit OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOTP,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify & Login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
