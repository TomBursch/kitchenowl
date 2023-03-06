import 'package:flutter/material.dart';

class SelectableButtonCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final bool selected;
  final void Function()? onPressed;
  final void Function()? onLongPressed;

  const SelectableButtonCard({
    Key? key,
    this.icon,
    required this.title,
    this.description,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: selected
          ? Theme.of(context).colorScheme.primary
          : ElevationOverlay.applySurfaceTint(
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              Theme.of(context).cardTheme.surfaceTintColor,
              1,
            ),
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Icon(
                  icon,
                  size: 64,
                  color:
                      selected ? Theme.of(context).colorScheme.onPrimary : null,
                ),
              ),
            Text(
              title,
              style: TextStyle(
                color:
                    selected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
            if (description != null && description!.isNotEmpty)
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(.7)
                          : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
