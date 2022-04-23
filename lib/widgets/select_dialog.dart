import 'package:flutter/material.dart';

class SelectDialog extends StatelessWidget {
  final List<SelectDialogOption> options;
  final String title;
  final String cancelText;

  const SelectDialog({
    Key? key,
    this.options = const [],
    this.title = "",
    this.cancelText = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        TextButton(
          child: Text(cancelText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class SelectDialogOption {
  final int id;
  final String name;
  final IconData? icon;

  SelectDialogOption(this.id, this.name, [this.icon]);
}
