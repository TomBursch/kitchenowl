import 'package:flutter/material.dart';

class ChoiceScroll extends StatelessWidget {
  final List<Widget> children;

  const ChoiceScroll({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const <Widget>[
              SizedBox(width: 12),
            ] +
            children
          ..add(const SizedBox(width: 12)),
      ),
    );
  }
}
