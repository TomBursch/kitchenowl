enum GridSize {
  small,
  normal,
  large,
}

class DynamicStyling {
  static int itemCrossAxisCount(double availableSpace, GridSize? sizing) =>
      (availableSpace ~/ 115).clamp(1, 9) - ((sizing?.index ?? 1) - 1);
}
