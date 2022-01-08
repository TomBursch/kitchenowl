import 'package:flutter/material.dart';

class TextDialog extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final String title;
  final String hintText;
  final String doneText;

  TextDialog({
    Key? key,
    this.title = "",
    this.doneText = "",
    this.hintText = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        onSubmitted: (t) => Navigator.of(context).pop(t),
        decoration: InputDecoration(hintText: hintText),
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
