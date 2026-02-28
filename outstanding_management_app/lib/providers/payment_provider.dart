import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import 'firebase_providers.dart';
import 'auth_provider.dart';
import 'invoice_provider.dart';

class PaymentQuery {
  final String paymentType;
  final String? partyId;

  PaymentQuery({
    required this.paymentType,
    this.partyId,
  });

  @override
  bool operator ==(Object old) =>
      old is PaymentQuery &&
      old.paymentType == paymentType &&
      old.partyId == partyId;

  @override
  int get hashCode => Object.hash(paymentType, partyId);
}

final paymentsProvider = StreamProvider.family<List<Payment>, PaymentQuery>((ref, query) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  Query<Map<String, dynamic>> firestoreQuery = ref.watch(firebaseFirestoreProvider)
    .collection('payments')
    .where('userId', isEqualTo: user.uid)
    .where('paymentType', isEqualTo: query.paymentType);
  
  if (query.partyId != null) {
    firestoreQuery = firestoreQuery.where('partyId', isEqualTo: query.partyId);
  }
  
  // NOTE: Requires composite index in Firestore
  firestoreQuery = firestoreQuery.orderBy('paymentDate', descending: true);
  
  return firestoreQuery
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(invoiceRepositoryProvider),
  );
});

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final InvoiceRepository _invoiceRepository;
  
  PaymentRepository(this._firestore, this._invoiceRepository);
  
  Future<String> recordPayment(Payment payment, List<PaymentAllocation> allocations) async {
    // We can either use a huge transaction to update the payment and ALL invoices,
    // or use a batch for the payment itself, and individual transactions for the invoices.
    // For simplicity & safety in this mockup without Cloud Functions, we'll do sequential transactions.
    
    // Validate total matches
    double totalAllocated = allocations.fold(0.0, (sum, alloc) => sum + alloc.allocatedAmount);
    // Allowing tiny float anomalies, but roughly it should match
    if ((totalAllocated - payment.totalAmount).abs() > 0.01) {
      throw Exception('Total allocated must equal total payment amount');
    }

    final batch = _firestore.batch();
    
    // Create payment document
    final docRef = _firestore.collection('payments').doc();
    batch.set(docRef, payment.toMap());
    
    // Add allocations subcollection
    for (var allocation in allocations) {
      final allocRef = docRef.collection('allocations').doc();
      batch.set(allocRef, allocation.toMap());
    }
    
    await batch.commit();

    // Now update invoice statuses locally since we are not relying on Cloud Functions
    for (var allocation in allocations) {
       await _invoiceRepository.updateInvoiceStatus(allocation.invoiceId, allocation.allocatedAmount);
    }
    
    return docRef.id;
  }
}
