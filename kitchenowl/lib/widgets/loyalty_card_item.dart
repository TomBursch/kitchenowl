import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:barcode/barcode.dart' as bc;

class LoyaltyCardItem extends StatelessWidget {
  final LoyaltyCard loyaltyCard;
  final VoidCallback? onTap;

  const LoyaltyCardItem({
    super.key,
    required this.loyaltyCard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = loyaltyCard.color != null
        ? Color(loyaltyCard.color!)
        : Theme.of(context).colorScheme.primaryContainer;
    final contrastColor = _getContrastColor(cardColor);
    final hasBarcode = loyaltyCard.barcodeData != null && loyaltyCard.barcodeData!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: cardColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor,
                HSLColor.fromColor(cardColor)
                    .withLightness(
                      (HSLColor.fromColor(cardColor).lightness - 0.1)
                          .clamp(0.0, 1.0),
                    )
                    .toColor(),
              ],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: contrastColor.withOpacity(0.1),
            highlightColor: contrastColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loyaltyCard.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: contrastColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: contrastColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasBarcode) ...[
                    // Barcode container - use Flexible instead of Expanded
                    Flexible(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 60,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _buildBarcode(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Barcode data text
                    Text(
                      _truncateMiddle(loyaltyCard.barcodeData!, 24),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: contrastColor.withOpacity(0.7),
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Icon(
                      Icons.credit_card_rounded,
                      size: 32,
                      color: contrastColor.withOpacity(0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final half = (maxLength - 3) ~/ 2;
    return '${text.substring(0, half)}...${text.substring(text.length - half)}';
  }

  Widget _buildBarcode(BuildContext context) {
    try {
      final barcodeType = _getBarcodeType(loyaltyCard.barcodeType ?? 'CODE128');
      final isQrLike = ['QR', 'DATAMATRIX', 'AZTEC', 'PDF417']
          .contains((loyaltyCard.barcodeType ?? '').toUpperCase());

      return BarcodeWidget(
        barcode: barcodeType,
        data: loyaltyCard.barcodeData ?? '',
        width: isQrLike ? 45 : 150,
        height: isQrLike ? 45 : 35,
        drawText: false,
        color: Colors.black,
        errorBuilder: (context, error) => Icon(
          Icons.qr_code_rounded,
          size: 32,
          color: Colors.grey.shade400,
        ),
      );
    } catch (e) {
      return Icon(
        Icons.qr_code_rounded,
        size: 32,
        color: Colors.grey.shade400,
      );
    }
  }

  bc.Barcode _getBarcodeType(String type) {
    switch (type.toUpperCase()) {
      case 'CODE128':
        return bc.Barcode.code128();
      case 'CODE39':
        return bc.Barcode.code39();
      case 'EAN13':
        return bc.Barcode.ean13();
      case 'EAN8':
        return bc.Barcode.ean8();
      case 'UPCA':
        return bc.Barcode.upcA();
      case 'UPCE':
        return bc.Barcode.upcE();
      case 'QR':
        return bc.Barcode.qrCode();
      case 'PDF417':
        return bc.Barcode.pdf417();
      case 'DATAMATRIX':
        return bc.Barcode.dataMatrix();
      case 'AZTEC':
        return bc.Barcode.aztec();
      case 'CODABAR':
        return bc.Barcode.codabar();
      case 'ITF':
        return bc.Barcode.itf();
      default:
        return bc.Barcode.code128();
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
