import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigService {
  // Feature flag for Smart OCR Invoice Scanner
  // Enabled initially for closed testing as requested.
  bool get isOcrScannerEnabled => true;
}

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});
