import 'dart:typed_data';

import 'package:kitchenowl/pages/barcode_scanner_page.dart';

/// Stub implementation for non-web platforms.
/// Always returns null since this functionality is web-only.
Future<BarcodeScanResult?> scanBarcodeFromImageBytesImpl(Uint8List bytes) async {
  return null;
}

