import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';

final collectionsAgentServiceProvider = Provider<CollectionsAgentService>((
  ref,
) {
  return CollectionsAgentService();
});

class CollectionsAgentService {
  CollectionsAgentService();

  Future<String> generateReminder(
    Invoice invoice,
    double totalPartyBalance,
  ) async {
    if (invoice.dueDate == null) {
      throw Exception('Invoice has no due date.');
    }

    final daysLate = DateTime.now().difference(invoice.dueDate!).inDays;

    // We only generate reminders for overdue invoices
    if (daysLate <= 0) {
      throw Exception('Invoice is not overdue yet.');
    }

    String toneInstruction;
    if (daysLate <= 7) {
      toneInstruction =
          "Tone: Friendly, polite, assuming they just forgot. Casual reminder.";
    } else if (daysLate <= 15) {
      toneInstruction =
          "Tone: Professional, direct, asking for an immediate update.";
    } else {
      toneInstruction =
          "Tone: Firm but professional. Clearly state the total outstanding balance and the specific invoice number. Request immediate payment.";
    }

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('generateOverdueReminder')
          .call({
            'customerName': invoice.partyName,
            'invoiceNumber': invoice.invoiceNumber,
            'invoiceAmount': invoice.totalAmount,
            'outstandingAmount': invoice.outstandingAmount,
            'totalPartyBalance': totalPartyBalance,
            'daysLate': daysLate,
            'toneInstruction': toneInstruction,
          });

      final message = result.data['message'] as String?;
      if (message == null || message.isEmpty) {
        throw Exception('Failed to generate reminder message.');
      }
      return message;
    } catch (e) {
      throw Exception('Error calling Cloud Function: $e');
    }
  }
}
