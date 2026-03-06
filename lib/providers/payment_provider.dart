import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import 'firebase_providers.dart';
import 'invoice_provider.dart';

class PaymentQuery {
  final String paymentType;
  final String? partyId;

  PaymentQuery({required this.paymentType, this.partyId});

  @override
  bool operator ==(Object other) =>
      other is PaymentQuery &&
      other.paymentType == paymentType &&
      other.partyId == partyId;

  @override
  int get hashCode => Object.hash(paymentType, partyId);
}

final paymentsProvider = StreamProvider.family<List<Payment>, PaymentQuery>((
  ref,
  query,
) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) return Stream.value([]);

  Query<Map<String, dynamic>> firestoreQuery = userDoc
      .collection('payments')
      .where('paymentType', isEqualTo: query.paymentType);

  if (query.partyId != null) {
    firestoreQuery = firestoreQuery.where('partyId', isEqualTo: query.partyId);
  }

  return firestoreQuery.snapshots().map((snapshot) {
    final payments = snapshot.docs
        .map((doc) => Payment.fromFirestore(doc))
        .toList();
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return payments;
  });
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref);
});

class PaymentRepository {
  final Ref _ref;

  PaymentRepository(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);
  InvoiceRepository get _invoiceRepo => _ref.read(invoiceRepositoryProvider);

  Future<String> recordPayment(
    Payment payment,
    List<PaymentAllocation> allocations,
  ) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');

    // Validation
    if (allocations.isNotEmpty) {
      for (var alloc in allocations) {
        if (alloc.allocatedAmount <= 0) {
          throw Exception('All allocated amounts must be greater than 0.');
        }
      }
      double totalAllocated = allocations.fold(
        0.0,
        (s, a) => s + a.allocatedAmount,
      );
      if ((totalAllocated - payment.totalAmount).abs() > 0.01) {
        throw Exception('Total allocated must equal total payment amount.');
      }
    }

    // Save payment doc
    final firestore = _ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();
    final docRef = userDoc.collection('payments').doc();
    batch.set(docRef, payment.toMap());

    // Save allocations subcollection
    for (var allocation in allocations) {
      final allocRef = docRef.collection('allocations').doc();
      batch.set(allocRef, allocation.toMap());
    }

    await batch.commit();

    // Update each invoice's paid/outstanding
    for (var allocation in allocations) {
      await _invoiceRepo.updateInvoiceStatus(
        allocation.invoiceId,
        allocation.allocatedAmount,
      );
    }

    return docRef.id;
  }

  Future<void> deletePayment(String paymentId) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');

    // Get allocations
    final allocationsSnapshot = await userDoc
        .collection('payments')
        .doc(paymentId)
        .collection('allocations')
        .get();

    // Reverse each allocation on its invoice
    for (var allocDoc in allocationsSnapshot.docs) {
      final data = allocDoc.data();
      final invoiceId = data['invoiceId'] as String;
      final amount = (data['allocatedAmount'] ?? 0).toDouble();
      await _invoiceRepo.updateInvoiceStatus(invoiceId, -amount);
    }

    // Delete allocations + payment
    final firestore = _ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();
    for (var doc in allocationsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(userDoc.collection('payments').doc(paymentId));
    await batch.commit();
  }
}
