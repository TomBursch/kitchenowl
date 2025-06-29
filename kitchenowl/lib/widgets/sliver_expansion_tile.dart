import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverExpansionTile extends StatefulWidget {
  final Duration animationDuration;
  final Widget title;
  final Widget sliver;
  final bool startCollapsed;
  final CrossAxisAlignment titleCrossAxisAlignment;

  const SliverExpansionTile({
    super.key,
    this.animationDuration = const Duration(milliseconds: 150),
    required this.title,
    required this.sliver,
    this.startCollapsed = false,
    this.titleCrossAxisAlignment = CrossAxisAlignment.end,
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
            padding: EdgeInsets.only(bottom: isExpanded ? 8 : 4),
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
                    icon: AnimatedRotation(
                      duration: widget.animationDuration,
                      turns: isExpanded ? 0 : .25,
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
                  const SizedBox(width: 8),
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
