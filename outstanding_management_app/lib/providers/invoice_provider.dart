import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';
import 'firebase_providers.dart';
import 'auth_provider.dart';

class InvoiceQuery {
  final String invoiceType;
  final String? partyId;
  final String? paymentStatus;

  InvoiceQuery({
    required this.invoiceType,
    this.partyId,
    this.paymentStatus,
  });

  @override
  bool operator ==(Object old) =>
      old is InvoiceQuery &&
      old.invoiceType == invoiceType &&
      old.partyId == partyId &&
      old.paymentStatus == paymentStatus;

  @override
  int get hashCode => Object.hash(invoiceType, partyId, paymentStatus);
}

final invoicesProvider = StreamProvider.family<List<Invoice>, InvoiceQuery>((ref, query) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  Query<Map<String, dynamic>> firestoreQuery = ref.watch(firebaseFirestoreProvider)
    .collection('invoices')
    .where('userId', isEqualTo: user.uid)
    .where('invoiceType', isEqualTo: query.invoiceType);
  
  if (query.partyId != null) {
    firestoreQuery = firestoreQuery.where('partyId', isEqualTo: query.partyId);
  }
  
  if (query.paymentStatus != null) {
    firestoreQuery = firestoreQuery.where('paymentStatus', isEqualTo: query.paymentStatus);
  }
  
  // NOTE: Requires composite index in Firestore
  firestoreQuery = firestoreQuery.orderBy('invoiceDate', descending: true);
  
  return firestoreQuery
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList());
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(firebaseFirestoreProvider));
});

class InvoiceRepository {
  final FirebaseFirestore _firestore;
  
  InvoiceRepository(this._firestore);
  
  Future<String> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final batch = _firestore.batch();
    
    // Create the main invoice document
    final docRef = _firestore.collection('invoices').doc();
    batch.set(docRef, invoice.toMap());
    
    // Add subcollection items
    for (var item in items) {
       final itemRef = docRef.collection('items').doc();
       batch.set(itemRef, item.toMap());
    }
    
    await batch.commit();
    return docRef.id;
  }
  
  Future<void> updateInvoiceStatus(String invoiceId, double additionalPayment) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('invoices').doc(invoiceId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Invoice does not exist!");
      
      final invoice = Invoice.fromFirestore(snapshot);
      
      final newPaidAmount = invoice.paidAmount + additionalPayment;
      final newOutstanding = invoice.totalAmount - newPaidAmount;
      
      String newStatus = 'unpaid';
      if (newOutstanding <= 0.0) {
        newStatus = 'paid';
      } else if (newPaidAmount > 0) {
        newStatus = 'partial';
      }
      
      transaction.update(docRef, {
        'paidAmount': newPaidAmount,
        'outstandingAmount': newOutstanding,
        'paymentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteInvoice(String invoiceId) async {
     final itemsSnapshot = await _firestore.collection('invoices').doc(invoiceId).collection('items').get();
     final batch = _firestore.batch();
     
     for (var itemDoc in itemsSnapshot.docs) {
       batch.delete(itemDoc.reference);
     }
     batch.delete(_firestore.collection('invoices').doc(invoiceId));
     await batch.commit();
  }
}
