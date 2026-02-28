import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/party_model.dart';
import 'firebase_providers.dart';
import 'auth_provider.dart';

final partiesProvider = StreamProvider.family<List<Party>, String>((ref, partyType) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  return ref.watch(firebaseFirestoreProvider)
    .collection('parties')
    .where('userId', isEqualTo: user.uid)
    .where('partyType', isEqualTo: partyType) // 'customer' or 'supplier'
    .orderBy('name')
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Party.fromFirestore(doc)).toList());
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepository(ref.watch(firebaseFirestoreProvider));
});

class PartyRepository {
  final FirebaseFirestore _firestore;
  
  PartyRepository(this._firestore);
  
  Future<String> createParty(Party party) async {
    final docRef = await _firestore.collection('parties').add(party.toMap());
    return docRef.id;
  }
  
  Future<void> updateParty(String partyId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('parties').doc(partyId).update(updates);
  }
  
  Future<void> deleteParty(String partyId) async {
    // In a real app, check if there are associated invoices/payments before deleting!
    await _firestore.collection('parties').doc(partyId).delete();
  }
  
  Future<Party> getParty(String partyId) async {
    final doc = await _firestore.collection('parties').doc(partyId).get();
    if (!doc.exists) {
      throw Exception('Party not found');
    }
    return Party.fromFirestore(doc);
  }
}
