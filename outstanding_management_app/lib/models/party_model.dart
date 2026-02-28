import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  final String id;
  final String userId;
  final String partyType; // "customer" or "supplier"
  final String name;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? gstNumber;
  final double openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Party({
    required this.id,
    required this.userId,
    required this.partyType,
    required this.name,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
    this.gstNumber,
    this.openingBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Party.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Party(
      id: doc.id,
      userId: data['userId'] ?? '',
      partyType: data['partyType'] ?? '',
      name: data['name'] ?? '',
      contactPerson: data['contactPerson'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      address: data['address'],
      gstNumber: data['gstNumber'],
      openingBalance: (data['openingBalance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'partyType': partyType,
      'name': name,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'openingBalance': openingBalance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Party copyWith({
    String? id,
    String? userId,
    String? partyType,
    String? name,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    String? gstNumber,
    double? openingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partyType: partyType ?? this.partyType,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
