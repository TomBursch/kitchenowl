import 'package:flutter/material.dart';

class ExpenseCategoryIcon extends StatelessWidget {
  final String name;
  final Color? color;
  final double? textScaleFactor;

  const ExpenseCategoryIcon({
    super.key,
    required this.name,
    this.color,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.secondaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(76),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          name.characters.isNotEmpty ? name.characters.first : "",
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize !=
                            null &&
                        textScaleFactor != null
                    ? Theme.of(context).textTheme.headlineSmall!.fontSize! *
                        textScaleFactor!
                    : null,
                color: color != null
                    ? color!.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
        ),
      ),
    );
  }
}
