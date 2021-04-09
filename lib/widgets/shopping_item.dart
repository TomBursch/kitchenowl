import 'package:flutter/material.dart';
import 'package:kitchenowl/models/item.dart';

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
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          selected
              ? Theme.of(context).accentColor
              : Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).cardColor
                  : Theme.of(context).disabledColor,
        ),
        elevation: MaterialStateProperty.all<double>(0),
      ),
      onPressed: onPressed != null ? () => onPressed(item) : null,
      onLongPress: onLongPressed != null ? () => onLongPressed(item) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: TextAlign.center,
          ),
          if (item is ItemWithDescription &&
              (item as ItemWithDescription).description != null &&
              (item as ItemWithDescription).description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                (item as ItemWithDescription).description,
                style: Theme.of(context).textTheme.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
