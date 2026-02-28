import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? companyName;
  final String? companyLogoUrl;
  final String? gstNumber;
  final String? address;
  final String invoicePrefix;
  final String currency;
  final String themePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.companyName,
    this.companyLogoUrl,
    this.gstNumber,
    this.address,
    this.invoicePrefix = "INV",
    this.currency = "INR",
    this.themePreference = "system",
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      avatarUrl: data['avatarUrl'],
      companyName: data['companyName'],
      companyLogoUrl: data['companyLogoUrl'],
      gstNumber: data['gstNumber'],
      address: data['address'],
      invoicePrefix: data['invoicePrefix'] ?? "INV",
      currency: data['currency'] ?? "INR",
      themePreference: data['themePreference'] ?? "system",
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'gstNumber': gstNumber,
      'address': address,
      'invoicePrefix': invoicePrefix,
      'currency': currency,
      'themePreference': themePreference,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? companyName,
    String? companyLogoUrl,
    String? gstNumber,
    String? address,
    String? invoicePrefix,
    String? currency,
    String? themePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      currency: currency ?? this.currency,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
