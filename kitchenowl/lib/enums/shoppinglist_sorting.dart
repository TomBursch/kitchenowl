import 'package:kitchenowl/models/item.dart';

enum ShoppinglistSorting {
  alphabetical,
  algorithmic,
  category;

  static void sortShoppinglistItems(
    List<ShoppinglistItem> shoppinglist,
    ShoppinglistSorting sorting,
  ) {
    if (shoppinglist.isEmpty) return;
    switch (sorting) {
      case ShoppinglistSorting.alphabetical:
      case ShoppinglistSorting.category:
        shoppinglist.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ShoppinglistSorting.algorithmic:
        shoppinglist.sort((a, b) {
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
