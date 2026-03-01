import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firebase_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }
  
  return ref.watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (snapshot.exists) {
          return AppUser.fromFirestore(snapshot);
        }
        return null;
      });
});

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

  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
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

  Future<void> signUpWithEmailPassword(String email, String password, String displayName) async {
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(user.uid).update(data);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
       throw Exception('Failed to send reset email: $e');
    }
  }
}
