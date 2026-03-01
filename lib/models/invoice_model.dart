import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified invoice/bill/challan record — no line items, no tax/discount.
class Invoice {
  final String id;
  final String partyId;
  final String partyName;
  final String invoiceType; // "sales" or "purchase"
  final String invoiceNumber;
  final String docType; // "Invoice/Bill" or "Challan"
  final DateTime invoiceDate;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String paymentStatus; // "paid", "partial", "unpaid"
  final String? description;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.docType,
    required this.invoiceDate,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.outstandingAmount,
    this.paymentStatus = 'unpaid',
    this.description,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      partyId: (data['partyId'] ?? '').toString(),
      partyName: (data['partyName'] ?? '').toString(),
      invoiceType: (data['invoiceType'] ?? '').toString(),
      invoiceNumber: (data['invoiceNumber'] ?? '').toString(),
      docType: (data['docType'] ?? 'Invoice/Bill').toString(),
      invoiceDate:
          (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      outstandingAmount: (data['outstandingAmount'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      description: data['description'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partyId': partyId,
      'partyName': partyName,
      'invoiceType': invoiceType,
      'invoiceNumber': invoiceNumber,
      'docType': docType,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'paymentStatus': paymentStatus,
      'description': description,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
