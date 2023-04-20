import 'package:flutter/material.dart';

class ChoiceScroll extends StatefulWidget {
  final List<Widget> children;
  final bool collapsable;
  final IconData? icon;

  const ChoiceScroll({
    super.key,
    required this.children,
    this.collapsable = false,
    this.icon,
  });

  @override
  State<ChoiceScroll> createState() => _ChoiceScrollState();
}

class _ChoiceScrollState extends State<ChoiceScroll> {
  late bool collapsed;

  @override
  void initState() {
    super.initState();
    collapsed = widget.collapsable;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      children: [
        const SizedBox(width: 12),
        if (widget.collapsable)
          IconButton(
            onPressed: () {
              setState(() {
                collapsed = !collapsed;
              });
            },
            icon: Icon(
              collapsed
                  ? (widget.icon ?? Icons.keyboard_arrow_right_rounded)
                  : Icons.keyboard_arrow_left_rounded,
            ),
          ),
        if (!collapsed) ...widget.children,
        const SizedBox(width: 12),
      ],
    );

    if (widget.collapsable) {
      child = AnimatedSize(
        duration: const Duration(milliseconds: 100),
        child: child,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: child,
    );
  }
}
