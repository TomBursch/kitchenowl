import 'package:flutter/material.dart';

class SelectDialog<T> extends StatelessWidget {
  final List<SelectDialogOption<T>> options;
  final String title;
  final String cancelText;

  const SelectDialog({
    super.key,
    this.options = const [],
    this.title = "",
    this.cancelText = "",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => TextButton(
                onPressed: () => Navigator.of(context).pop(option.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      if (option.icon != null) Icon(option.icon),
                      if (option.icon != null) const SizedBox(width: 8),
                      Expanded(child: Text(option.name)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
      actions: [
        FilledButton(
          child: Text(cancelText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class SelectDialogOption<T> {
  final T id;
  final String name;
  final IconData? icon;

  SelectDialogOption(this.id, this.name, [this.icon]);
}
