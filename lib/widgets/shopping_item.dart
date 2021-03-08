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
        backgroundColor: MaterialStateProperty.all<Color>(selected
            ? Theme.of(context).accentColor
            : Theme.of(context).disabledColor),
        elevation: MaterialStateProperty.all<double>(0),
      ),
      onPressed: () => onPressed(item),
      onLongPress: () => onLongPressed(item),
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
          if (item is ShoppinglistItem &&
              (item as ShoppinglistItem).description != null &&
              (item as ShoppinglistItem).description.isNotEmpty)
            Text((item as ShoppinglistItem).description),
        ],
      ),
    );
  }
}
