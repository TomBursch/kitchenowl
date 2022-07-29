import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KitchenOwlSwitch extends StatelessWidget {
  final bool value;
  final Function(bool)? onChanged;

  const KitchenOwlSwitch({Key? key, required this.value, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.9,
      child: CupertinoSwitch(
        value: value,
        activeColor: Theme.of(context).colorScheme.secondary,
        onChanged: onChanged,
      ),
    );
  }
}
