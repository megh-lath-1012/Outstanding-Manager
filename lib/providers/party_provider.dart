import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/party_model.dart';
import 'firebase_providers.dart';

final partiesProvider = StreamProvider.family<List<Party>, String>((
  ref,
  partyType,
) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) return Stream.value([]);

  return userDoc
      .collection('parties')
      .where('partyType', isEqualTo: partyType)
      .snapshots()
      .map((snapshot) {
        final parties = snapshot.docs
            .map((doc) => Party.fromFirestore(doc))
            .toList();
        parties.sort((a, b) => a.name.compareTo(b.name));
        return parties;
      });
});

/// Provider that returns ALL parties regardless of type
final allPartiesProvider = StreamProvider<List<Party>>((ref) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) return Stream.value([]);

  return userDoc.collection('parties').snapshots().map((snapshot) {
    final parties = snapshot.docs
        .map((doc) => Party.fromFirestore(doc))
        .toList();
    parties.sort((a, b) => a.name.compareTo(b.name));
    return parties;
  });
});

final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepository(ref);
});

class PartyRepository {
  final Ref _ref;

  PartyRepository(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);

  /// Check for duplicate party name (case-insensitive) before creating
  Future<String> createParty(Party party) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');

    // Duplicate check (case-insensitive)
    final existing = await userDoc
        .collection('parties')
        .where('partyType', isEqualTo: party.partyType)
        .get();

    final duplicate = existing.docs.any(
      (doc) =>
          (doc.data()['name'] as String? ?? '').toLowerCase() ==
          party.name.toLowerCase(),
    );
    if (duplicate) {
      throw Exception(
        'A ${party.partyType} named "${party.name}" already exists.',
      );
    }

    final docRef = await userDoc.collection('parties').add(party.toMap());
    return docRef.id;
  }

  Future<void> updateParty(String partyId, Map<String, dynamic> updates) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await userDoc.collection('parties').doc(partyId).update(updates);
  }

  Future<void> deleteParty(String partyId) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');
    await userDoc.collection('parties').doc(partyId).delete();
  }

  Future<Party> getParty(String partyId) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');
    final doc = await userDoc.collection('parties').doc(partyId).get();
    if (!doc.exists) throw Exception('Party not found');
    return Party.fromFirestore(doc);
  }
}
