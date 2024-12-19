import 'package:flutter/material.dart';
import 'package:kitchenowl/models/shoppinglist.dart';

class ShoppingListChoiceChip extends StatelessWidget {
  final ShoppingList shoppingList;
  final bool selected;
  final bool canDelete;
  final void Function(bool)? onSelected;
  final void Function()? onDeleted;

  const ShoppingListChoiceChip(
      {super.key,
      required this.shoppingList,
      this.canDelete = true,
      this.selected = false,
      this.onSelected,
      this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: Row(children: <Widget>[
        ChoiceChip(
          showCheckmark: false,
          label: Text(
            shoppingList.name +
                (shoppingList.items.isNotEmpty
                    ? " (${shoppingList.items.length})"
                    : ""),
            style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.onPrimary : null,
            ),
          ),
          selected: selected,
          elevation: shoppingList.items.isNotEmpty ? 2 : 0,
          selectedColor: Theme.of(context).colorScheme.secondary,
          onSelected: onSelected,
        ),
        if (selected && canDelete)
          IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDeleted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints())
      ]),
    );
  }
}
