import 'package:flutter/material.dart';

class CustomCheckboxListTile extends StatelessWidget {
  final Widget trailing;
  final Widget title;
  final Function(bool) onChanged;
  final bool value;

  const CustomCheckboxListTile({
    Key key,
    this.trailing,
    this.title,
    this.onChanged,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      trailing: trailing,
      onTap: () => onChanged(!value),
      leading: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
