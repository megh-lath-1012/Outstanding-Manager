import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firebaseFirestoreProvider)
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

/// Returns the current user's doc reference: users/{uid}
/// All subcollections (parties, invoices, payments) hang off this.
final userDocProvider = Provider<DocumentReference?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(firebaseFirestoreProvider).collection('users').doc(user.uid);
});
