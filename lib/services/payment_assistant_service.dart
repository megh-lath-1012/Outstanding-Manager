import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/invoice_model.dart';
import '../models/party_model.dart';
import '../models/payment_model.dart';
import '../providers/firebase_providers.dart';

final paymentAssistantServiceProvider = Provider<PaymentAssistantService>((
  ref,
) {
  return PaymentAssistantService(ref);
});

class PaymentAssistantService {
  final Ref _ref;

  PaymentAssistantService(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);

  /// Main entry point for the "Rapid Financial Entry Agent"
  Future<Map<String, dynamic>> processRapidEntry(String prompt) async {
    final userDoc = _userDoc;
    if (userDoc == null) throw Exception('User not authenticated.');

    // 1. Call the "Aggressive Parsing" Cloud Function
    final extracted = await _callRapidEntryFunction(prompt);

    final String type = extracted['type']; // 'sale', 'purchase', 'payment'
    final String partyName = extracted['partyName'];
    final double amount = (extracted['amount'] as num).toDouble();

    // 2. Party Intelligence: Fuzzy search
    final party = await _findPartyByName(userDoc, partyName);

    if (party == null) {
      // Return flag to create party
      return {
        ...extracted,
        'shouldCreateParty': true,
        'matchedParty': null,
        'allocations': null,
      };
    }

    // 3. Silent Allocation (if payment)
    List<Map<String, dynamic>>? allocations;
    if (type == 'payment') {
      try {
        final allocObjects = await _allocatePayment(userDoc, party, amount);
        allocations = allocObjects
            .map(
              (a) => {
                'invoiceId': a.invoiceId,
                'invoiceNumber': a.invoiceNumber,
                'allocatedAmount': a.allocatedAmount,
              },
            )
            .toList();
      } catch (e) {
        // If allocation fails (e.g. no invoices), we might still want to record as unallocated
        // but for now let's just return empty allocations or handle error
        allocations = [];
      }
    }

    return {
      ...extracted,
      'shouldCreateParty': false,
      'matchedParty': party,
      'allocations': allocations,
    };
  }

  Future<Map<String, dynamic>> _callRapidEntryFunction(String prompt) async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('rapidFinancialEntry').call({'prompt': prompt});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Extraction failed: $e');
    }
  }

  /// Processes natural language prompt and returns formatted JSON map for [recordPayment]
  Future<Map<String, dynamic>> processPaymentPrompt(String prompt) async {
    final userDoc = _userDoc;
    if (userDoc == null) {
      throw Exception('User not authenticated.');
    }

    // 1. Extract entities using Cloud Function
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
      'allocations': allocations
          .map(
            (a) => {
              'invoiceId': a.invoiceId,
              'invoiceNumber': a.invoiceNumber,
              'allocatedAmount': a.allocatedAmount,
            },
          )
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _extractEntities(String prompt) async {
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      ).httpsCallable('processPaymentAssistant').call({'prompt': prompt});

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Error calling Payment Assistant Cloud Function: $e');
    }
  }

  /// Processes natural language prompt for Sales or Purchases
  Future<Map<String, dynamic>> processTransactionPrompt({
    required String prompt,
    required String type,
  }) async {
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('processTransactionAssistant')
          .call({'prompt': prompt, 'type': type});

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Error calling Transaction Assistant Cloud Function: $e');
    }
  }

  Future<Party?> _findPartyByName(
    DocumentReference userDoc,
    String partyName,
  ) async {
    final snapshot = await userDoc.collection('parties').get();

    try {
      final doc = snapshot.docs.firstWhere(
        (doc) =>
            (doc.data()['name'] as String).toLowerCase() ==
                partyName.toLowerCase() ||
            (doc.data()['name'] as String).toLowerCase().contains(
              partyName.toLowerCase(),
            ),
      );
      return Party.fromFirestore(doc);
    } catch (e) {
      // Try startsWith as fallback
      try {
        final doc = snapshot.docs.firstWhere(
          (doc) => (doc.data()['name'] as String).toLowerCase().startsWith(
            partyName.toLowerCase().substring(0, min(3, partyName.length)),
          ),
        );
        return Party.fromFirestore(doc);
      } catch (_) {
        return null;
      }
    }
  }

  int min(int a, int b) => a < b ? a : b;

  Future<List<PaymentAllocation>> _allocatePayment(
    DocumentReference userDoc,
    Party party,
    double amount,
  ) async {
    // Fetch unpaid/partial invoices
    final snapshot = await userDoc
        .collection('invoices')
        .where('partyId', isEqualTo: party.id)
        .where('paymentStatus', whereIn: ['unpaid', 'partial'])
        .orderBy('invoiceDate', descending: false) // oldest first
        .get();

    final invoices = snapshot.docs
        .map((doc) => Invoice.fromFirestore(doc))
        .toList();

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
        ),
      );

      remainingAmount -= allocateToThis;
    }

    if (allocations.isEmpty) {
      throw Exception(
        'No outstanding invoices found for ${party.name} to allocate this payment.',
      );
    }

    if (remainingAmount > 0.01) {
      throw Exception(
        'Payment amount (\$amount) exceeds total outstanding balance for ${party.name}.',
      );
    }

    return allocations;
  }
}
