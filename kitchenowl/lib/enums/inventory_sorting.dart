import 'package:kitchenowl/models/item.dart';

enum InventorySorting {
  alphabetical,
  algorithmic,
  category;

  static void sortInventoryItems(
    List<Item> inventory,
    InventorySorting sorting,
  ) {
    if (inventory.isEmpty) return;
    switch (sorting) {
      case InventorySorting.alphabetical:
      case InventorySorting.category:
        inventory.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case InventorySorting.algorithmic:
        inventory.sort((a, b) {
          final int ordering = a.ordering.compareTo(b.ordering);
          // Ordering of 0 means not sortable and should be at the back
          if (ordering != 0 && a.ordering == 0) return 1;
          if (ordering != 0 && b.ordering == 0) return -1;

          return ordering;
        });
        break;
    }
  }
}
