// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:kitchenowl/pages/barcode_scanner_page.dart';

@JS('decodeBarcode')
external JSPromise<JSAny?> _decodeBarcode(JSString base64Data);

/// Web implementation that calls the JavaScript barcode scanner.
Future<BarcodeScanResult?> scanBarcodeFromImageBytesImpl(Uint8List bytes) async {
  try {
    // Convert bytes to base64
    final base64Data = base64Encode(bytes);
    
    // Call the JavaScript function
    final jsResult = await _decodeBarcode(base64Data.toJS).toDart;
    
    if (jsResult == null) {
      return null;
    }

    // Cast to JSObject and extract properties
    final jsObject = jsResult as JSObject;
    final dataProperty = (jsObject as dynamic).data;
    final typeProperty = (jsObject as dynamic).type;
    
    final data = (dataProperty as JSString?)?.toDart;
    final type = (typeProperty as JSString?)?.toDart;
    
    if (data != null && type != null) {
      return BarcodeScanResult(data: data, type: type);
    }
    
    return null;
  } catch (e) {
    print('Web barcode scanner error: $e');
    return null;
  }
}
