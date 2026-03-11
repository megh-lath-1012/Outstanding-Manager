import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result_model.dart';

final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

class OCRService {
  OCRService();

  Future<OcrResult> parseInvoiceImage(Uint8List imageBytes) async {
    try {
      // Convert image bytes to base64 for transfer
      final base64Image = base64Encode(imageBytes);

      final result = await FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('parseInvoiceImage')
          .call({
            'image': base64Image,
          });

      if (result.data == null) {
        throw Exception('Failed to get result from OCR service.');
      }

      return OcrResult.fromMap(Map<String, dynamic>.from(result.data));
    } catch (e) {
      print('OCR Error: $e');
      throw Exception('Error parsing invoice image: $e');
    }
  }
}
