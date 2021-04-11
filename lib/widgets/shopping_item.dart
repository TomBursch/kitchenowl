import 'package:flutter/material.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/widgets/selectable_button_card.dart';

class ShoppingItemWidget<T extends Item> extends StatelessWidget {
  final T item;
  final void Function(T) onPressed;
  final void Function(T) onLongPressed;
  final bool selected;

  const ShoppingItemWidget({
    Key key,
    this.item,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableButtonCard(
      title: item.name,
      selected: selected,
      description: (item is ItemWithDescription)
          ? (item as ItemWithDescription).description
          : null,
      onPressed: onPressed != null ? () => onPressed(item) : null,
      onLongPressed: onLongPressed != null ? () => onLongPressed(item) : null,
    );
  }
}
