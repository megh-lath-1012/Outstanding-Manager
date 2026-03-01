import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';
import 'firebase_providers.dart';

class InvoiceQuery {
  final String invoiceType; // 'sales' or 'purchase'
  final String? partyId;
  final String? paymentStatus;
  final String? searchTerm;

  InvoiceQuery({
    required this.invoiceType,
    this.partyId,
    this.paymentStatus,
    this.searchTerm,
  });

  @override
  bool operator ==(Object other) =>
      other is InvoiceQuery &&
      other.invoiceType == invoiceType &&
      other.partyId == partyId &&
      other.paymentStatus == paymentStatus &&
      other.searchTerm == searchTerm;

  @override
  int get hashCode =>
      Object.hash(invoiceType, partyId, paymentStatus, searchTerm);
}

/// Streams all invoices matching the query, sorted oldest first
final invoicesProvider = StreamProvider.family<List<Invoice>, InvoiceQuery>((
  ref,
  query,
) {
  final userDoc = ref.watch(userDocProvider);
  if (userDoc == null) return Stream.value([]);

  Query<Map<String, dynamic>> firestoreQuery = userDoc
      .collection('invoices')
      .where('invoiceType', isEqualTo: query.invoiceType);

  if (query.partyId != null) {
    firestoreQuery = firestoreQuery.where('partyId', isEqualTo: query.partyId);
  }

  if (query.paymentStatus != null) {
    firestoreQuery = firestoreQuery.where(
      'paymentStatus',
      isEqualTo: query.paymentStatus,
    );
  }

  return firestoreQuery.snapshots().map((snapshot) {
    var invoices = snapshot.docs
        .map((doc) => Invoice.fromFirestore(doc))
        .toList();
    // Sort oldest first (ascending date)
    invoices.sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));

    // Client-side search filter (party name or invoice number)
    if (query.searchTerm != null && query.searchTerm!.isNotEmpty) {
      final term = query.searchTerm!.toLowerCase();
      invoices = invoices
          .where(
            (inv) =>
                inv.partyName.toLowerCase().contains(term) ||
                inv.invoiceNumber.toLowerCase().contains(term),
          )
          .toList();
    }

    return invoices;
  });
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref);
});

class InvoiceRepository {
  final Ref _ref;

  InvoiceRepository(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);

  /// Create a simple sales/purchase record (no line items)
  Future<String> createInvoice(Invoice invoice) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');

    final docRef = await userDoc.collection('invoices').add(invoice.toMap());
    return docRef.id;
  }

  /// Update invoice payment status after a payment allocation
  Future<void> updateInvoiceStatus(
    String invoiceId,
    double additionalPayment,
  ) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');

    await _ref.read(firebaseFirestoreProvider).runTransaction((
      transaction,
    ) async {
      final docRef = userDoc.collection('invoices').doc(invoiceId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Invoice does not exist!");

      final invoice = Invoice.fromFirestore(snapshot);

      final newPaidAmount = invoice.paidAmount + additionalPayment;
      final newOutstanding = invoice.totalAmount - newPaidAmount;

      String newStatus = 'unpaid';
      if (newOutstanding <= 0.01) {
        newStatus = 'paid';
      } else if (newPaidAmount > 0.01) {
        newStatus = 'partial';
      }

      transaction.update(docRef, {
        'paidAmount': newPaidAmount < 0 ? 0.0 : newPaidAmount,
        'outstandingAmount': newOutstanding < 0 ? 0.0 : newOutstanding,
        'paymentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('Not authenticated');
    await userDoc.collection('invoices').doc(invoiceId).delete();
  }
}
