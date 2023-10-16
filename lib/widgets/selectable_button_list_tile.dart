import 'package:flutter/material.dart';

class SelectableButtonListTile extends StatefulWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final bool selected;
  final bool raised;
  final void Function()? onPressed;
  final void Function()? onLongPressed;

  const SelectableButtonListTile({
    super.key,
    required this.title,
    this.icon,
    this.description,
    required this.selected,
    this.onPressed,
    this.onLongPressed,
    this.raised = true,
  });

  @override
  State<SelectableButtonListTile> createState() =>
      _SelectableButtonListTileState();
}

class _SelectableButtonListTileState extends State<SelectableButtonListTile> {
  bool mouseHover = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: !widget.raised ? 0 : null,
      color: !widget.raised
          ? ElevationOverlay.applySurfaceTint(
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surfaceTint,
              1.5,
            )
          : null,
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
        child: ListTile(
          leading: widget.selected
              ? const Icon(Icons.check_rounded)
              : widget.icon != null
                  ? Icon(widget.icon)
                  : null,
          title:
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          selected: widget.selected,
          subtitle: (widget.description?.isNotEmpty ?? false)
              ? Text(
                  widget.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color!
                            .withAlpha(170),
                      ),
                )
              : null,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPressed,
          contentPadding: const EdgeInsets.only(left: 16, right: 8),
          trailing: (widget.onLongPressed != null && mouseHover)
              ? IconButton(
                  onPressed: widget.onLongPressed,
                  color: widget.selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  icon: const Icon(Icons.more_horiz_rounded),
                )
              : null,
        ),
      ),
    );
  }
}
