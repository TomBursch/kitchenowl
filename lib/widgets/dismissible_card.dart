import 'package:flutter/material.dart';

class DismissibleCard extends StatelessWidget {
  final Future<bool> Function(DismissDirection)? confirmDismiss;
  final void Function(DismissDirection)? onDismissed;
  final void Function()? onTap;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool displayDraggable;

  const DismissibleCard({
    required Key key,
    this.confirmDismiss,
    this.onDismissed,
    this.onTap,
    required this.title,
    this.subtitle,
    this.trailing,
    this.displayDraggable = false,
  })  : assert(!displayDraggable || trailing == null,
            "Trailing cannot be set when displayDraggable is set"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      confirmDismiss: confirmDismiss,
      onDismissed: onDismissed,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        child: ListTile(
          title: title,
          onTap: onTap,
          subtitle: subtitle,
          trailing: displayDraggable ? const Icon(Icons.drag_handle) : trailing,
        ),
      ),
    );
  }
}
