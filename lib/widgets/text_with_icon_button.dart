import 'package:flutter/material.dart';

class TextWithIconButton extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Widget icon;
  final void Function()? onPressed;

  const TextWithIconButton({
    super.key,
    required this.title,
    this.style,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: style ?? Theme.of(context).textTheme.headline6,
          ),
        ),
        IconButton(
          icon: icon,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
