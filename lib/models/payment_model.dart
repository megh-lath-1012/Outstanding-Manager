import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentAllocation {
  final String? id;
  final String invoiceId;
  final String invoiceNumber;
  final double allocatedAmount;

  PaymentAllocation({
    this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.allocatedAmount,
  });

  factory PaymentAllocation.fromMap(Map<String, dynamic> data, [String? id]) {
    return PaymentAllocation(
      id: id,
      invoiceId: data['invoiceId'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'allocatedAmount': allocatedAmount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class Payment {
  final String id;
  final String partyId;
  final String partyName;
  final String paymentType; // "receipt" or "payment"
  final DateTime paymentDate;
  final double totalAmount;
  final String
  paymentMethod; // "cash", "bank_transfer", "upi", "cheque", "card", "other"
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Allocations (loaded separately via subcollection usually, but kept here for convenience if needed)
  final List<PaymentAllocation>? allocations;

  Payment({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.paymentType,
    required this.paymentDate,
    required this.totalAmount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.allocations,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      partyId: (data['partyId'] ?? '').toString(),
      partyName: (data['partyName'] ?? '').toString(),
      paymentType: data['paymentType'] ?? '',
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: (data['paymentMethod'] ?? 'cash').toString(),
      referenceNumber: data['referenceNumber']?.toString(),
      notes: data['notes']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partyId': partyId,
      'partyName': partyName,
      'paymentType': paymentType,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
