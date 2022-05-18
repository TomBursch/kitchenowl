import 'package:flutter/material.dart';

class SliverText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  const SliverText(
    this.data, {
    Key? key,
    this.style,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(
        child: Text(
          data,
          style: style,
        ),
      ),
    );
  }
}
