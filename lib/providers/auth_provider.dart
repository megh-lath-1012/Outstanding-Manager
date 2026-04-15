import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_providers.dart';

export 'firebase_providers.dart' show authStateProvider, appUserProvider;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFirestoreProvider),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureUserExists(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'displayName': user.displayName ?? 'New User',
        'invoicePrefix': 'INV',
        'currency': 'INR',
        'themePreference': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      }
      throw Exception(e.message ?? 'An error occurred during sign in.');
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user profile in Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'invoicePrefix': 'INV',
          'currency': 'INR',
          'themePreference': 'system',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Optionally send email verification
        // await credential.user!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      }
      throw Exception(e.message ?? 'An error occurred during registration.');
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google Auth was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _ensureUserExists(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithSmsCode(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _ensureUserExists(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with Phone: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).update(data);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final uid = user.uid;

    // 1. Delete user collections (Parties, Invoices, Payments)
    // Note: In a production app, this might be better handled by a Cloud Function
    // or a more robust batching mechanism if there's a lot of data.

    final collections = ['parties', 'invoices', 'payments'];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // 2. Delete user profile
    await _firestore.collection('users').doc(uid).delete();

    // 3. Delete Auth Account
    await user.delete();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }
}
