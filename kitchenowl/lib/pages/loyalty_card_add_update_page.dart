import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/pages/barcode_scanner_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class LoyaltyCardAddUpdatePage extends StatefulWidget {
  final Household household;
  final LoyaltyCard? loyaltyCard;

  const LoyaltyCardAddUpdatePage({
    super.key,
    required this.household,
    this.loyaltyCard,
  });

  @override
  State<LoyaltyCardAddUpdatePage> createState() =>
      _LoyaltyCardAddUpdatePageState();
}

class _LoyaltyCardAddUpdatePageState extends State<LoyaltyCardAddUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeDataController;
  late TextEditingController _descriptionController;
  String? _detectedBarcodeType;
  bool _isAutoDetected = false;
  bool _showManualEntry = false;
  Color? _selectedColor;
  bool _isLoading = false;
  bool _isScanning = false;

  static const List<String> _barcodeTypes = [
    'CODE128',
    'CODE39',
    'EAN13',
    'EAN8',
    'UPCA',
    'UPCE',
    'QR',
    'PDF417',
    'DATAMATRIX',
    'AZTEC',
    'CODABAR',
    'ITF',
  ];

  bool get isEditing => widget.loyaltyCard != null;
  bool get hasBarcode =>
      _barcodeDataController.text.isNotEmpty && _detectedBarcodeType != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.loyaltyCard?.name);
    _barcodeDataController =
        TextEditingController(text: widget.loyaltyCard?.barcodeData);
    _descriptionController =
        TextEditingController(text: widget.loyaltyCard?.description);
    _detectedBarcodeType = widget.loyaltyCard?.barcodeType;
    _isAutoDetected = false;
    _selectedColor = widget.loyaltyCard?.color != null
        ? Color(widget.loyaltyCard!.color!)
        : null;
    // Show manual entry if editing existing card
    _showManualEntry = isEditing;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeDataController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _scanFromCamera() async {
    final result = await Navigator.of(context).push<BarcodeScanResult>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _barcodeDataController.text = result.data;
        _detectedBarcodeType = result.type;
        _isAutoDetected = true;
        _showManualEntry = false;
      });
    }
  }

  Future<void> _scanFromGallery() async {
    setState(() {
      _isScanning = true;
    });

    try {
      await _scanFromGalleryMobile();
    } catch (e) {
      if (mounted) {
        _showNoBarcodeError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _scanFromGalleryMobile() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }

    final controller = MobileScannerController();
    final BarcodeCapture? capture = await controller.analyzeImage(image.path);
    await controller.dispose();

    if (capture != null && capture.barcodes.isNotEmpty && mounted) {
      final barcode = capture.barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          _barcodeDataController.text = barcode.rawValue!;
          _detectedBarcodeType = barcodeFormatToString(barcode.format);
          _isAutoDetected = true;
          _showManualEntry = false;
        });
      } else {
        _showNoBarcodeError();
      }
    } else if (mounted) {
      _showNoBarcodeError();
    }
  }

  void _showNoBarcodeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.noBarcodesFound),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? AppLocalizations.of(context)!.loyaltyCardEdit
              : AppLocalizations.of(context)!.loyaltyCardAdd,
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: AppLocalizations.of(context)!.save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan buttons section
            if (!hasBarcode || _showManualEntry) ...[
              _buildScanSection(),
              const SizedBox(height: 24),
            ],

            // Detected barcode display
            if (hasBarcode && !_showManualEntry) ...[
              _buildDetectedBarcodeCard(),
              const SizedBox(height: 16),
            ],

            // Manual entry section (collapsible)
            if (_showManualEntry) ...[
              _buildManualEntrySection(),
              const SizedBox(height: 16),
            ],

            // Toggle manual entry
            if (hasBarcode && !_showManualEntry)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showManualEntry = true;
                  });
                },
                icon: const Icon(Icons.edit, size: 18),
                label: Text(AppLocalizations.of(context)!.enterManually),
              ),

            const SizedBox(height: 8),

            // Store Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.name,
                hintText: AppLocalizations.of(context)!.loyaltyCardNameHint,
                prefixIcon: const Icon(Icons.store),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                hintText: AppLocalizations.of(context)!.optional,
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Color Picker
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text(AppLocalizations.of(context)!.color),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor ??
                      Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              onTap: _pickColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    // Show camera + gallery scanning options (works on both web and mobile)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.scanBarcode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isScanning ? null : _scanFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(kIsWeb
                        ? AppLocalizations.of(context)!.webcam
                        : AppLocalizations.of(context)!.camera),
                  ),
                ),
                const SizedBox(width: 12),
                if (!kIsWeb)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : _scanFromGallery,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(AppLocalizations.of(context)!.gallery),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showManualEntry = true;
                  });
                },
                child: Text(AppLocalizations.of(context)!.enterManually),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedBarcodeCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.barcodeDetected,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _barcodeDataController.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_detectedBarcodeType ?? ''),
                  avatar: const Icon(Icons.qr_code, size: 18),
                ),
                if (_isAutoDetected) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${AppLocalizations.of(context)!.autoDetected})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _scanFromCamera,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(AppLocalizations.of(context)!.scanBarcode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntrySection() {
    return Column(
      children: [
        // Barcode Data
        TextFormField(
          controller: _barcodeDataController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.barcodeData,
            hintText: AppLocalizations.of(context)!.barcodeDataHint,
            prefixIcon: const Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.text,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Barcode Type Dropdown
        DropdownButtonFormField<String>(
          value: _barcodeTypes.contains(_detectedBarcodeType)
              ? _detectedBarcodeType
              : 'CODE128',
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.barcodeType,
            prefixIcon: const Icon(Icons.qr_code),
          ),
          items: _barcodeTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _detectedBarcodeType = value;
                _isAutoDetected = false;
              });
            }
          },
        ),
      ],
    );
  }

  Future<void> _pickColor() async {
    Color pickerColor =
        _selectedColor ?? Theme.of(context).colorScheme.primaryContainer;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.color),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) {
              pickerColor = color;
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedColor = pickerColor;
              });
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.select),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loyaltyCard = LoyaltyCard(
        id: widget.loyaltyCard?.id,
        name: _nameController.text.trim(),
        barcodeType: _barcodeDataController.text.trim().isNotEmpty
            ? (_detectedBarcodeType ?? 'CODE128')
            : null,
        barcodeData: _barcodeDataController.text.trim().isNotEmpty
            ? _barcodeDataController.text.trim()
            : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor?.value,
      );

      bool success;
      LoyaltyCard? result;
      if (isEditing) {
        success =
            await ApiService.getInstance().updateLoyaltyCard(loyaltyCard);
        result = loyaltyCard;
      } else {
        result = await ApiService.getInstance().addLoyaltyCard(
          widget.household,
          loyaltyCard,
        );
        success = result != null;
      }

      if (success && mounted) {
        Navigator.of(context).pop(result);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
