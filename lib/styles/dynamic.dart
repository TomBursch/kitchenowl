class DynamicStyling {
  static int itemCrossAxisCount(double availableSpace) =>
      (availableSpace ~/ 115).clamp(1, 9);
}
