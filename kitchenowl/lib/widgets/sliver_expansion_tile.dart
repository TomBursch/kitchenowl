import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverExpansionTile extends StatefulWidget {
  final Duration animationDuration;
  final Widget title;
  final Widget sliver;
  final bool startCollapsed;
  final CrossAxisAlignment titleCrossAxisAlignment;

  /// Shrinks the header chrome so it matches a slim (very dense) list.
  final bool slim;

  const SliverExpansionTile({
    super.key,
    this.animationDuration = const Duration(milliseconds: 150),
    required this.title,
    required this.sliver,
    this.startCollapsed = false,
    this.titleCrossAxisAlignment = CrossAxisAlignment.end,
    this.slim = false,
  });

  @override
  State<SliverExpansionTile> createState() => _SliverExpansionTileState();
}

class _SliverExpansionTileState extends State<SliverExpansionTile> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = !widget.startCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: AnimatedPadding(
            padding: widget.slim
                ? EdgeInsets.only(bottom: isExpanded ? 2 : 1)
                : EdgeInsets.only(bottom: isExpanded ? 8 : 4),
            duration: widget.animationDuration,
            child: InkWell(
              onTap: () => setState(() {
                isExpanded = !isExpanded;
              }),
              child: Row(
                crossAxisAlignment: widget.titleCrossAxisAlignment,
                children: [
                  Expanded(
                    child: widget.title,
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      isExpanded = !isExpanded;
                    }),
                    // The 48x48 default would set the header height on its own
                    padding: widget.slim ? EdgeInsets.zero : null,
                    visualDensity:
                        widget.slim ? VisualDensity.compact : null,
                    constraints: widget.slim
                        ? const BoxConstraints(minWidth: 28, minHeight: 28)
                        : null,
                    iconSize: widget.slim ? 18 : null,
                    icon: AnimatedRotation(
                      duration: widget.animationDuration,
                      turns: isExpanded ? 0 : .25,
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
                  SizedBox(width: widget.slim ? 4 : 8),
                ],
              ),
            ),
          ),
        ),
        SliverAnimatedSwitcher(
          duration: widget.animationDuration,
          child: !isExpanded
              ? const SliverToBoxAdapter(child: SizedBox())
              : widget.sliver,
        ),
      ],
    );
  }
}
