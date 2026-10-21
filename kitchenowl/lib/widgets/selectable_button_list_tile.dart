import 'package:material_ui/material_ui.dart';
import 'package:kitchenowl/styles/dynamic.dart';

class SelectableButtonListTile extends StatefulWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final bool selected;
  final bool raised;
  final void Function()? onPressed;
  final void Function()? onLongPressed;
  final Widget? extraOption;
  final ListStyle listStyle;

  /// Separator below the row (slim style only). Suppressed on the last row of
  /// a group so the category break stays the stronger visual boundary.
  final bool showDivider;

  const SelectableButtonListTile({
    super.key,
    required this.title,
    this.icon,
    this.description,
    required this.selected,
    this.onPressed,
    this.onLongPressed,
    this.raised = true,
    this.extraOption,
    this.listStyle = ListStyle.cards,
    this.showDivider = true,
  });

  @override
  State<SelectableButtonListTile> createState() =>
      _SelectableButtonListTileState();
}

class _SelectableButtonListTileState extends State<SelectableButtonListTile> {
  bool mouseHover = false;

  @override
  Widget build(BuildContext context) {
    final bool slim = widget.listStyle == ListStyle.slim;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    final Widget listItem = MouseRegion(
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
        visualDensity:
            slim ? const VisualDensity(horizontal: -4, vertical: -4) : null,
        minVerticalPadding: slim ? 1 : null,
        minTileHeight: slim ? 30 : null,
        horizontalTitleGap: slim ? 8 : null,
        leading: widget.selected
            ? Icon(Icons.check_rounded, size: slim ? 20 : null)
            : widget.icon != null
                ? Icon(widget.icon,
                    size: slim ? 20 : null,
                    color: !widget.raised
                        ? Theme.of(context).iconTheme.color!.withAlpha(85)
                        : Theme.of(context).iconTheme.color!.withAlpha(170))
                : null,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: slim ? DynamicStyling.slimFontSize : null,
              color: !widget.raised
                  ? Theme.of(context).textTheme.bodyMedium!.color!.withAlpha(85)
                  : Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .color!
                      .withAlpha(170)),
        ),
        selected: widget.selected,
        subtitle: (widget.description?.isNotEmpty ?? false)
            ? Text(
                widget.description!,
                maxLines: slim ? 1 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: !widget.raised
                        ? Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color!
                            .withAlpha(85)
                        : Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .color!
                            .withAlpha(170)),
              )
            : null,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPressed,
        contentPadding: slim
            ? const EdgeInsets.only(left: 12, right: 4)
            : const EdgeInsets.only(left: 16, right: 8),
        trailing: (widget.extraOption != null && mouseHover)
            ? widget.extraOption
            : (widget.onLongPressed != null && mouseHover)
                ? IconButton(
                    onPressed: widget.onLongPressed,
                    color: widget.selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                    // Keep the hover button from stretching a slim row
                    padding: slim ? EdgeInsets.zero : null,
                    visualDensity: slim ? VisualDensity.compact : null,
                    constraints: slim
                        ? const BoxConstraints(minWidth: 24, minHeight: 24)
                        : null,
                    iconSize: slim ? 18 : null,
                    icon: const Icon(Icons.more_horiz_rounded),
                  )
                : null,
      ),
    );

    if (slim) {
      if (!widget.showDivider) return listItem;

      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: onSurface.withAlpha(36), width: 0.5),
          ),
        ),
        child: listItem,
      );
    }

    return (widget.listStyle == ListStyle.cards)
        ? Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: !widget.raised ? 0 : null,
            color: !widget.raised
                ? ElevationOverlay.applySurfaceTint(
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceTint,
                    1.5,
                  )
                : null,
            child: listItem,
          )
        : listItem;
  }
}
