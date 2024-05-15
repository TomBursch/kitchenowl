import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kitchenowl/kitchenowl.dart';

class KitchenOwlColorPickerDialog extends StatefulWidget {
  final Color? initialColor;

  const KitchenOwlColorPickerDialog({super.key, this.initialColor});

  @override
  State<KitchenOwlColorPickerDialog> createState() =>
      _KitchenOwlColorPickerDialogState();
}

class _KitchenOwlColorPickerDialogState
    extends State<KitchenOwlColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor ?? Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.colorSelect,
      ),
      scrollable: true,
      content: ColorPicker(
        enableAlpha: false,
        pickerColor: selectedColor,
        labelTypes: const [],
        pickerAreaBorderRadius: BorderRadius.circular(14),
        onColorChanged: (c) => selectedColor = c,
      ),
      actions: [
        TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).disabledColor,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.cancel,
          ),
        ),
        FilledButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              Colors.redAccent,
            ),
            foregroundColor: WidgetStateProperty.all<Color>(
              Colors.white,
            ),
          ),
          onPressed: () =>
              Navigator.of(context).pop(const Nullable<Color>.empty()),
          child: Text(
            AppLocalizations.of(context)!.remove,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(Nullable(selectedColor)),
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
