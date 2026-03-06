import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/invoice_model.dart';
import '../providers/firebase_providers.dart';

final collectionsAgentServiceProvider = Provider<CollectionsAgentService>((ref) {
  return CollectionsAgentService(ref);
});

class CollectionsAgentService {
  final Ref _ref;

  // Ideally, get this from secure storage or env variables.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  CollectionsAgentService(this._ref);

  DocumentReference? get _userDoc => _ref.read(userDocProvider);

  Future<String> generateReminder(Invoice invoice, double totalPartyBalance) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured (GEMINI_API_KEY).');
    }

    if (invoice.dueDate == null) {
      throw Exception('Invoice has no due date.');
    }

    final daysLate = DateTime.now().difference(invoice.dueDate!).inDays;
    
    // We only generate reminders for overdue invoices
    if (daysLate <= 0) {
      throw Exception('Invoice is not overdue yet.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
    );

    String toneInstruction;
    if (daysLate <= 7) {
      toneInstruction = "Tone: Friendly, polite, assuming they just forgot. Casual reminder.";
    } else if (daysLate <= 15) {
      toneInstruction = "Tone: Professional, direct, asking for an immediate update.";
    } else {
      toneInstruction = "Tone: Firm but professional. Clearly state the total outstanding balance and the specific invoice number. Request immediate payment.";
    }

    final prompt = '''
You are "Outstanding Management App", an automated collections agent for a small business. 
Generate a professional WhatsApp/Email reminder message for a customer to pay their overdue invoice.

Context:
Customer Name: ${invoice.partyName}
Invoice Number: ${invoice.invoiceNumber}
Invoice Amount: \u20b9${invoice.totalAmount}
Outstanding Amount for this invoice: \u20b9${invoice.outstandingAmount}
Total Outstanding Balance for this customer: \u20b9$totalPartyBalance
Days Overdue: $daysLate
$toneInstruction

Instructions:
1. Make it sound human and professional.
2. If the tone instruction mentions including the total balance or invoice number, make sure they are included naturally.
3. Keep it brief and suitable for a WhatsApp message or short email.
4. Do NOT include placeholders like [Your Name] or [Company Name]. Just write the message body itself.
5. Provide ONLY the final message string, no extra conversational text or formatting outside the message.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text;

    if (responseText == null || responseText.isEmpty) {
      throw Exception('Failed to generate reminder message.');
    }

    return responseText.trim();
  }
}
