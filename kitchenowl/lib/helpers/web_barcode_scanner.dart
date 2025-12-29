import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:kitchenowl/pages/barcode_scanner_page.dart';

// Conditional import for web-specific implementation
import 'web_barcode_scanner_stub.dart'
    if (dart.library.js) 'web_barcode_scanner_web.dart' as impl;

/// Scans a barcode from image bytes on web platform.
/// Returns null if no barcode is found or if not on web.
Future<BarcodeScanResult?> scanBarcodeFromImageBytes(Uint8List bytes) async {
  if (!kIsWeb) {
    return null;
  }
  return impl.scanBarcodeFromImageBytesImpl(bytes);
}

