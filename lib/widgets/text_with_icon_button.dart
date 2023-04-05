import 'package:flutter/material.dart';

class TextWithIconButton extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final Widget icon;
  final String? tooltip;
  final void Function()? onPressed;

  const TextWithIconButton({
    super.key,
    required this.title,
    this.style,
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: style ?? Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
