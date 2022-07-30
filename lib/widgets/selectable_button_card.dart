import 'package:flutter/material.dart';

class SelectableButtonCard extends StatelessWidget {
  final String title;
  final String? description;
  final bool selected;
  final void Function()? onPressed;
  final void Function()? onLongPressed;

  const SelectableButtonCard({
    Key? key,
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
          ? Theme.of(context).colorScheme.secondary
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
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    selected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
            ),
            if (description != null && description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  description!,
                  style: Theme.of(context).textTheme.caption!.copyWith(
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
              ),
          ],
        ),
      ),
    );
  }
}
