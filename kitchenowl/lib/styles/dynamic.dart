enum GridSize {
  small,
  normal,
  large,
}

enum ListStyle {
  minimalist,
  cards,
}

class DynamicStyling {
  static int itemCrossAxisCount(double availableSpace, GridSize? sizing) =>
      (availableSpace ~/ 115).clamp(1, 9) - ((sizing?.index ?? 1) - 1);
}

class ShoppingListStyle {
  final bool advancedItemView;
  final bool isList;
  final bool? allRaised;
  final GridSize gridSize;
  final ListStyle listStyle;

  /// Show the item's category emoji as the leading icon on lines/tiles
  /// that don't have their own item icon (Listonic-style).
  final bool showCategoryIcon;

  const ShoppingListStyle({
    this.advancedItemView = false,
    this.isList = false,
    this.allRaised,
    this.gridSize = GridSize.normal,
    this.listStyle = ListStyle.cards,
    this.showCategoryIcon = false,
  });
}
