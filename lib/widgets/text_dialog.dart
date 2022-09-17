import 'package:flutter/material.dart';

class TextDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String doneText;
  final TextInputType? textInputType;
  final bool Function(String)? isInputValid;
  final String? initialText;

  const TextDialog({
    super.key,
    this.title = "",
    this.doneText = "",
    this.hintText = "",
    this.initialText,
    this.textInputType,
    this.isInputValid,
  });

  @override
  State<TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<TextDialog> {
  bool validText = true;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    if (widget.isInputValid != null && widget.initialText != null) {
      validText = widget.isInputValid!(widget.initialText!);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        autofocus: true,
        onChanged: (value) {
          if (widget.isInputValid != null) {
            setState(() {
              validText = widget.isInputValid!(value);
            });
          }
        },
        onSubmitted: (t) {
          if (validText) Navigator.of(context).pop(t);
        },
        decoration: InputDecoration(hintText: widget.hintText),
        keyboardType: widget.textInputType,
      ),
      actions: [
        TextButton(
          onPressed: validText
              ? () => Navigator.of(context).pop(controller.text)
              : null,
          child: Text(widget.doneText),
        ),
      ],
    );
  }
}
