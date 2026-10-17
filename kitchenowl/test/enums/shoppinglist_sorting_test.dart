import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/item.dart';

List<String> sortedNames(List<String> names, ShoppinglistSorting sorting) {
  final items = names.map((e) => Item(name: e)).toList();
  ShoppinglistSorting.sortShoppinglistItems(items, sorting);
  return items.map((e) => e.name).toList();
}

void main() {
  for (final sorting in [
    ShoppinglistSorting.alphabetical,
    ShoppinglistSorting.category,
  ]) {
    group("Sorting ${sorting.name}", () {
      test("ignores case", () {
        expect(
          sortedNames(["banana", "Apple", "cherry", "Banana bread"], sorting),
          ["Apple", "banana", "Banana bread", "cherry"],
        );
      });

      test("sorts names with diacritics under their base letter", () {
        expect(
          sortedNames(["Banana", "Zucchini", "Äpple", "Avocado"], sorting),
          ["Äpple", "Avocado", "Banana", "Zucchini"],
        );
      });

      test("keeps ligatures next to their spelled out form", () {
        expect(
          sortedNames(["Œuf 2", "Orange", "Oats", "oeuf 1"], sorting),
          ["Oats", "oeuf 1", "Œuf 2", "Orange"],
        );
      });

      test("orders names that only differ in accents consistently", () {
        expect(sortedNames(["Pâte", "pate", "Pate"], sorting),
            sortedNames(["Pate", "Pâte", "pate"], sorting));
      });
    });
  }
}
