import 'package:flutter/material.dart';

class CustomCheckboxListTile extends StatelessWidget {
  final Widget trailing;
  final Widget title;
  final Widget subtitle;
  final Function(bool) onChanged;
  final bool value;

  const CustomCheckboxListTile({
    Key key,
    this.trailing,
    this.title,
    this.subtitle,
    this.onChanged,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      trailing: trailing,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      leading: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
