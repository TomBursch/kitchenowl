import 'package:flutter/material.dart';

class SelectableButtonCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final bool selected;
  final void Function()? onPressed;
  final void Function()? onLongPressed;
  final Widget? extraOption;

  const SelectableButtonCard({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
    this.extraOption,
  });

  @override
  State<SelectableButtonCard> createState() => _SelectableButtonCardState();
}

class _SelectableButtonCardState extends State<SelectableButtonCard> {
  bool mouseHover = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.selected ? 1 : 0,
      color: widget.selected
          ? Theme.of(context).colorScheme.primary
          : ElevationOverlay.applySurfaceTint(
              Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              Theme.of(context).cardTheme.surfaceTintColor ??
                  Theme.of(context).colorScheme.surfaceTint,
              1,
            ),
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            mouseHover = true;
          });
        },
        onExit: (event) {
          setState(() {
            mouseHover = false;
          });
        },
        child: InkWell(
          onTap: widget.onPressed,
          onSecondaryTap: widget.onLongPressed,
          onLongPress: widget.onLongPressed,
          child: Stack(
            alignment: AlignmentDirectional.topEnd,
            children: [
              if (widget.extraOption != null && mouseHover) widget.extraOption!,
              if (widget.extraOption == null &&
                  widget.onLongPressed != null &&
                  mouseHover)
                IconButton(
                  onPressed: widget.onLongPressed,
                  color: widget.selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                      child: LayoutBuilder(
                        builder: (context, constraint) => Icon(
                          widget.icon,
                          size: constraint.maxWidth / 2.4,
                          color: widget.selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                      ),
                    ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.description?.isNotEmpty ?? false)
                    Text(
                      widget.description!,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: widget.selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimary
                                    .withAlpha(178)
                                : null,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
