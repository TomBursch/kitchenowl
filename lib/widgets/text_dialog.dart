import 'package:flutter/material.dart';

class TextDialog extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final String title;
  final String hintText;
  final String doneText;
  final TextInputType? textInputType;

  TextDialog({
    super.key,
    this.title = "",
    this.doneText = "",
    this.hintText = "",
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        onSubmitted: (t) => Navigator.of(context).pop(t),
        decoration: InputDecoration(hintText: hintText),
        keyboardType: textInputType,
      ),
      actions: [
        TextButton(
          child: Text(doneText),
          onPressed: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    );
  }
}
