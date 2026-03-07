import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Result returned from the barcode scanner
class BarcodeScanResult {
  final String data;
  final String type;

  const BarcodeScanResult({
    required this.data,
    required this.type,
  });
}

/// Helper to convert BarcodeFormat to our string type
String barcodeFormatToString(BarcodeFormat format) {
  switch (format) {
    case BarcodeFormat.code128:
      return 'CODE128';
    case BarcodeFormat.code39:
      return 'CODE39';
    case BarcodeFormat.code93:
      return 'CODE93';
    case BarcodeFormat.codabar:
      return 'CODABAR';
    case BarcodeFormat.ean13:
      return 'EAN13';
    case BarcodeFormat.ean8:
      return 'EAN8';
    case BarcodeFormat.itf:
      return 'ITF';
    case BarcodeFormat.upcA:
      return 'UPCA';
    case BarcodeFormat.upcE:
      return 'UPCE';
    case BarcodeFormat.qrCode:
      return 'QR';
    case BarcodeFormat.pdf417:
      return 'PDF417';
    case BarcodeFormat.aztec:
      return 'AZTEC';
    case BarcodeFormat.dataMatrix:
      return 'DATAMATRIX';
    default:
      return 'CODE128';
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController _controller;
  bool _hasScanned = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() {
      _hasScanned = true;
    });

    final result = BarcodeScanResult(
      data: barcode.rawValue!,
      type: barcodeFormatToString(barcode.format),
    );

    Navigator.of(context).pop(result);
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  void _switchCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    // Torch only available on mobile platforms
    final bool canUseTorch = !kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.scanBarcode),
        actions: [
          if (canUseTorch)
            IconButton(
              icon: Icon(
                _torchEnabled ? Icons.flash_on : Icons.flash_off,
              ),
              onPressed: _toggleTorch,
              tooltip: _torchEnabled
                  ? AppLocalizations.of(context)!.flashOff
                  : AppLocalizations.of(context)!.flashOn,
            ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded),
              onPressed: _switchCamera,
              tooltip: AppLocalizations.of(context)!.switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Instructions
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  AppLocalizations.of(context)!.pointCameraAtBarcode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

