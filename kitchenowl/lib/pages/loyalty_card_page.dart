import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/loyalty_card_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/pages/loyalty_card_add_update_page.dart';
import 'package:barcode/barcode.dart' as bc;
import 'package:wakelock_plus/wakelock_plus.dart';

class LoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard loyaltyCard;
  final Household household;

  const LoyaltyCardPage({
    super.key,
    required this.loyaltyCard,
    required this.household,
  });

  @override
  State<LoyaltyCardPage> createState() => _LoyaltyCardPageState();
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  late LoyaltyCardCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = LoyaltyCardCubit(widget.loyaltyCard);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    cubit.close();
    super.dispose();
  }

  bool _isQrLike(String type) {
    return ['QR', 'DATAMATRIX', 'AZTEC', 'PDF417']
        .contains(type.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<LoyaltyCardCubit, LoyaltyCardState>(
        builder: (context, state) {
          final loyaltyCard = state.loyaltyCard;
          final cardColor = loyaltyCard.color != null
              ? Color(loyaltyCard.color!)
              : Theme.of(context).colorScheme.primaryContainer;
          final contrastColor = _getContrastColor(cardColor);
          final hasBarcode = loyaltyCard.barcodeData != null && loyaltyCard.barcodeData!.isNotEmpty;
          final isQrLike = hasBarcode ? _isQrLike(loyaltyCard.barcodeType!) : false;
          final isLongData = hasBarcode ? loyaltyCard.barcodeData!.length > 20 : false;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(loyaltyCard.name),
              leading: BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/household/${widget.household.id}/loyalty-cards');
                  }
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _editCard(context, loyaltyCard),
                  tooltip: AppLocalizations.of(context)!.edit,
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (hasBarcode)
                      PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: const Icon(Icons.copy),
                          title: Text(AppLocalizations.of(context)!.copyBarcode),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'copy') {
                      _copyBarcode(context, loyaltyCard);
                    } else if (value == 'delete') {
                      _deleteCard(context, loyaltyCard);
                    }
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Card with barcode
                      Hero(
                        tag: 'loyalty_card_${loyaltyCard.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cardColor,
                                  HSLColor.fromColor(cardColor)
                                      .withLightness(
                                        (HSLColor.fromColor(cardColor).lightness - 0.12)
                                            .clamp(0.0, 1.0),
                                      )
                                      .toColor(),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: cardColor.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasBarcode) ...[
                                    // Barcode container
                                    Container(
                                      padding: EdgeInsets.all(isQrLike ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _buildBarcode(context, loyaltyCard),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Barcode data - tappable to copy
                                    InkWell(
                                      onTap: () => _copyBarcode(context, loyaltyCard),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: contrastColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                isLongData
                                                    ? _truncateMiddle(loyaltyCard.barcodeData!, 30)
                                                    : loyaltyCard.barcodeData!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: contrastColor,
                                                      fontFamily: 'monospace',
                                                      letterSpacing: 1,
                                                    ),
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.copy_rounded,
                                              size: 18,
                                              color: contrastColor.withOpacity(0.7),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // No barcode - show store icon
                                    Icon(
                                      Icons.store_rounded,
                                      size: 64,
                                      color: contrastColor.withOpacity(0.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Description
                      if (loyaltyCard.description != null &&
                          loyaltyCard.description!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loyaltyCard.description!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Screen on indicator
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.brightness_high_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.keepScreenOn,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final half = (maxLength - 3) ~/ 2;
    return '${text.substring(0, half)}...${text.substring(text.length - half)}';
  }

  Widget _buildBarcode(BuildContext context, LoyaltyCard loyaltyCard) {
    if (loyaltyCard.barcodeType == null || loyaltyCard.barcodeData == null) {
      return const SizedBox.shrink();
    }
    try {
      final barcodeType = _getBarcodeType(loyaltyCard.barcodeType!);
      final isQrLike = _isQrLike(loyaltyCard.barcodeType!);
      // Don't show text for QR codes or long data (like URLs)
      final showText = !isQrLike && loyaltyCard.barcodeData!.length <= 20;

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isQrLike ? 220 : 300,
        ),
        child: BarcodeWidget(
          barcode: barcodeType,
          data: loyaltyCard.barcodeData!,
          width: isQrLike ? 200 : double.infinity,
          height: isQrLike ? 200 : 80,
          drawText: showText,
          color: Colors.black,
          errorBuilder: (context, error) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.barcodeInvalid,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.barcodeCannotDisplay,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
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

  void _copyBarcode(BuildContext context, LoyaltyCard loyaltyCard) {
    if (loyaltyCard.barcodeData == null) return;
    Clipboard.setData(ClipboardData(text: loyaltyCard.barcodeData!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editCard(BuildContext context, LoyaltyCard loyaltyCard) async {
    final result = await Navigator.of(context).push<LoyaltyCard>(
      MaterialPageRoute(
        builder: (context) => LoyaltyCardAddUpdatePage(
          household: widget.household,
          loyaltyCard: loyaltyCard,
        ),
      ),
    );
    if (result != null) {
      cubit.updateCard(result);
    }
  }

  Future<void> _deleteCard(BuildContext context, LoyaltyCard loyaltyCard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(
          AppLocalizations.of(context)!
              .loyaltyCardDeleteConfirmation(loyaltyCard.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await cubit.deleteCard();
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
