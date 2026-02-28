import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String? id;
  final String description;
  final double quantity;
  final double rate;
  final double amount;
  
  InvoiceItem({
    this.id,
    required this.description,
    this.quantity = 1.0,
    required this.rate,
    required this.amount,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> data, [String? id]) {
    return InvoiceItem(
      id: id,
      description: data['description'] ?? '',
      quantity: (data['quantity'] ?? 1).toDouble(),
      rate: (data['rate'] ?? 0).toDouble(),
      amount: (data['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class Invoice {
  final String id;
  final String userId;
  final String partyId;
  final String partyName;
  final String invoiceType; // "sales" or "purchase"
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final String discountType; // "percentage" or "fixed"
  final double discountValue;
  final double discountAmount;
  final double taxPercentage;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String paymentStatus; // "paid", "partial", "unpaid"
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Line items (loaded separately via subcollection usually, but kept here for convenience if needed)
  final List<InvoiceItem>? items;

  Invoice({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.partyName,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    this.subtotal = 0.0,
    this.discountType = 'fixed',
    this.discountValue = 0.0,
    this.discountAmount = 0.0,
    this.taxPercentage = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.outstandingAmount,
    this.paymentStatus = 'unpaid',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      userId: data['userId'] ?? '',
      partyId: data['partyId'] ?? '',
      partyName: data['partyName'] ?? '',
      invoiceType: data['invoiceType'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      invoiceDate: (data['invoiceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discountType: data['discountType'] ?? 'fixed',
      discountValue: (data['discountValue'] ?? 0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0).toDouble(),
      taxPercentage: (data['taxPercentage'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      outstandingAmount: (data['outstandingAmount'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyId': partyId,
      'partyName': partyName,
      'invoiceType': invoiceType,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'subtotal': subtotal,
      'discountType': discountType,
      'discountValue': discountValue,
      'discountAmount': discountAmount,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'outstandingAmount': outstandingAmount,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isOverdue {
    if (paymentStatus == 'paid') return false;
    if (dueDate == null) return false;
    
    final today = DateTime.now();
    return dueDate!.isBefore(DateTime(today.year, today.month, today.day));
  }
}
