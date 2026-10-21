enum GridSize {
  small,
  normal,
  large,
}

enum ListStyle {
  minimalist,
  cards,
  // Appended at the end: the index is persisted in the preferences
  slim,
}

class DynamicStyling {
  static int itemCrossAxisCount(double availableSpace, GridSize? sizing) =>
      (availableSpace ~/ 115).clamp(1, 9) - ((sizing?.index ?? 1) - 1);

  /// Shared by item rows and category headers in [ListStyle.slim] so the two
  /// always render at the same size.
  static const double slimFontSize = 20;
}

class ShoppingListStyle {
  final bool advancedItemView;
  final bool isList;
  final bool? allRaised;
  final GridSize gridSize;
  final ListStyle listStyle;

  const ShoppingListStyle({
    this.advancedItemView = false,
    this.isList = false,
    this.allRaised,
    this.gridSize = GridSize.normal,
    this.listStyle = ListStyle.cards,
  });
}
