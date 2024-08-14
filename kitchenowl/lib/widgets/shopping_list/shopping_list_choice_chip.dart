import 'package:flutter/material.dart';
import 'package:kitchenowl/models/shoppinglist.dart';

class ShoppingListChoiceChip extends StatelessWidget {
  final ShoppingList shoppingList;
  final bool selected;
  final void Function(bool)? onSelected;

  const ShoppingListChoiceChip({
    super.key,
    required this.shoppingList,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: ChoiceChip(
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
    );
  }
}
