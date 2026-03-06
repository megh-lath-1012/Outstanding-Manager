import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';
import '../models/party_model.dart';
import '../models/payment_model.dart';
import '../providers/firebase_providers.dart';

final paymentAssistantServiceProvider = Provider<PaymentAssistantService>((ref) {
  return PaymentAssistantService(ref);
});

class PaymentAssistantService {
  final Ref _ref;

  // Ideally, get this from secure storage or env variables.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  PaymentAssistantService(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);

  /// Processes natural language prompt and returns formatted JSON map for [recordPayment]
  Future<Map<String, dynamic>> processPaymentPrompt(String prompt) async {
    final userDoc = _userDoc;
    if (userDoc == null) {
      throw Exception('User not authenticated.');
    }

    if (_apiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured (GEMINI_API_KEY).');
    }

    // 1. Extract entities using Gemini API
    final extractedData = await _extractEntities(prompt);
    
    final String partyName = extractedData['partyName'] as String;
    final double amount = (extractedData['amount'] as num).toDouble();
    final String paymentMethod = extractedData['paymentMethod'] as String;

    // 2. Fetch Party to get Party ID
    final party = await _findPartyByName(userDoc, partyName);
    if (party == null) {
      throw Exception('Could not find party "$partyName" in your records.');
    }

    // 3. Fetch Unpaid Invoices and apply FIFO allocation
    final allocations = await _allocatePayment(userDoc, party, amount);
    
    // 4. Return Output
    return {
      'partyId': party.id,
      'partyName': party.name,
      'paymentType': party.partyType == 'customer' ? 'receipt' : 'payment',
      'paymentDate': DateTime.now().toIso8601String(),
      'totalAmount': amount,
      'paymentMethod': paymentMethod,
      'allocations': allocations.map((a) => {
        'invoiceId': a.invoiceId,
        'invoiceNumber': a.invoiceNumber,
        'allocatedAmount': a.allocatedAmount,
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _extractEntities(String prompt) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      )
    );

    final instruction = '''
You are an intelligent payment recording assistant. Extract the following entities from the natural language text and return them strictly in JSON format.

{
  "partyName": "The exact name of the customer or supplier (e.g., John Smith, Acme Corp)",
  "amount": The numeric value of the amount paid or received without currency symbols (e.g., 500.0),
  "paymentMethod": "One of these exact string values: 'cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'"
}

If the payment method is not clearly specified, default to 'other'. Do not include extra text, just the raw JSON output.
Text: "$prompt"
''';

    final response = await model.generateContent([Content.text(instruction)]);
    final responseText = response.text;
    
    if (responseText == null || responseText.isEmpty) {
      throw Exception('Failed to extract entities from prompt.');
    }

    try {
      return jsonDecode(responseText) as Map<String, dynamic>;
    } catch (e) {
      // In case the model wrapped it in markdown code blocks
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanedText) as Map<String, dynamic>;
    }
  }

  Future<Party?> _findPartyByName(DocumentReference userDoc, String partyName) async {
    // Attempting an exact, although case-insensitive if possible, search.
    // Firestore doesn't do native precise case-insensitive easily without secondary arrays.
    // Fetching all might be needed if party lists are small, but let's do a direct query first.
    final snapshot = await userDoc.collection('parties').get();
    
    try {
      final doc = snapshot.docs.firstWhere(
        (doc) => (doc.data()['name'] as String).toLowerCase().contains(partyName.toLowerCase())
      );
      return Party.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<List<PaymentAllocation>> _allocatePayment(
      DocumentReference userDoc, Party party, double amount) async {
    
    // Fetch unpaid/partial invoices
    final snapshot = await userDoc
        .collection('invoices')
        .where('partyId', isEqualTo: party.id)
        .where('paymentStatus', whereIn: ['unpaid', 'partial'])
        .orderBy('invoiceDate', descending: false) // oldest first
        .get();

    final invoices = snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

    double remainingAmount = amount;
    List<PaymentAllocation> allocations = [];

    for (var invoice in invoices) {
      if (remainingAmount <= 0) break;

      double allocateToThis = invoice.outstandingAmount;
      
      if (remainingAmount < invoice.outstandingAmount) {
         allocateToThis = remainingAmount;
      }
      
      allocations.add(
        PaymentAllocation(
          invoiceId: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          allocatedAmount: allocateToThis,
        )
      );

      remainingAmount -= allocateToThis;
    }

    if (allocations.isEmpty) {
      throw Exception('No outstanding invoices found for ${party.name} to allocate this payment.');
    }

    // Validation: Check total allocated matches (or at least doesn't exceed) amount
    // If remainingAmount > 0, it means the payment amount was greater than the total outstanding balance.
    // The requirements say: "Validation: Ensure the total allocated equals the total payment and never exceeds an invoice's outstandingAmount."
    if (remainingAmount > 0.01) {
       throw Exception('Payment amount (\$amount) exceeds total outstanding balance for ${party.name}.');
    }

    return allocations;
  }
}
