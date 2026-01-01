enum GridSize {
  small,
  normal,
  large,
}

enum ListStyle {
  minimalist,
  cards
}

class DynamicStyling {
  static int itemCrossAxisCount(double availableSpace, GridSize? sizing) =>
      (availableSpace ~/ 115).clamp(1, 9) - ((sizing?.index ?? 1) - 1);
}

class ShoppingListStyle {
  final bool advancedItemView;
  final bool isList;
  final GridSize gridSize;
  final ListStyle listStyle;

  const ShoppingListStyle({
    this.advancedItemView = false,
    this.isList = false,
    this.gridSize = GridSize.normal,
    this.listStyle = ListStyle.minimalist,
  });
}