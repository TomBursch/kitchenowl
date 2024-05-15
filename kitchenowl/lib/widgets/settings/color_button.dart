import 'package:flutter/material.dart';

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final void Function()? onTap;

  const ColorButton({
    super.key,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      height: 32,
      width: 32,
      child: Material(
        color: color,
        shape: CircleBorder(
          side: selected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 4,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
        ),
      ),
    );
  }
}
