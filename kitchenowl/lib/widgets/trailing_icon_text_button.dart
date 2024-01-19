import 'package:flutter/material.dart';

class TrailingIconTextButton extends StatelessWidget {
  final void Function()? onPressed;
  final Icon icon;
  final String text;

  const TrailingIconTextButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 4,
          right: 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 4),
            icon,
          ],
        ),
      ),
    );
  }
}
