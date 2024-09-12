import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SliverImageAppBar extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? imageHash;
  final Object? Function() popValue;
  final List<Widget>? Function(bool isCollapsed)? actions;

  const SliverImageAppBar({
    super.key,
    required this.title,
    required this.imageUrl,
    this.imageHash,
    required this.popValue,
    this.actions,
  });

  @override
  State<SliverImageAppBar> createState() => SliverImageAppBarrState();
}

class SliverImageAppBarrState extends State<SliverImageAppBar> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final actions =
        widget.actions != null ? widget.actions!(isCollapsed) : null;

    return SliverAppBar(
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        bool localIsCollapsed = constraints.biggest.height <=
            MediaQuery.of(context).padding.top + kToolbarHeight - 16 + 32;
        if (isCollapsed != localIsCollapsed)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              setState(() {
                isCollapsed = localIsCollapsed;
              });
          });

        return FlexibleImageSpaceBar(
          title: widget.title,
          imageUrl: widget.imageUrl,
          imageHash: widget.imageHash,
          isCollapsed: isCollapsed,
          actionCount: isCollapsed ? actions?.length ?? 0 : 0,
        );
      }),
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child:
            (widget.imageUrl == null || widget.imageUrl!.isEmpty || isCollapsed
                ? IconButton.new
                : IconButton.filledTonal)(
          key: ValueKey('back' + isCollapsed.toString()),
          icon: const BackButtonIcon(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context))
              Navigator.of(context).pop(widget.popValue());
            else
              context.go("/");
          },
        ),
      ),
      expandedHeight: widget.imageUrl?.isNotEmpty ?? false
          ? (MediaQuery.of(context).size.height / 3.3).clamp(160, 350)
          : null,
      pinned: true,
      actions: actions,
    );
  }
}
