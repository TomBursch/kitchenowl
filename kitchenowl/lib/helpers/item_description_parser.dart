abstract class ItemDescriptionParser {
  static List<(String, String)> getSuggestions(String desciption) {
    if (desciption.isEmpty)
      return [
        ("1", "1"),
        ("2", "2"),
        ("3", "3"),
        ("200g", "200g"),
        ("500g", "500g"),
        ("500ml", "500ml")
      ];

    final regex = RegExp(r"\d+");
    if (regex.hasMatch(desciption)) {
      int number = int.parse(regex.firstMatch(desciption)!.group(0)!);
      if (number < 10)
        return [
          ("+1", desciption.replaceFirst(regex, (number + 1).toString())),
          ("+2", desciption.replaceFirst(regex, (number + 2).toString())),
          ("+5", desciption.replaceFirst(regex, (number + 5).toString())),
          ("+10", desciption.replaceFirst(regex, (number + 10).toString()))
        ];

      return [
        ("+10", desciption.replaceFirst(regex, (number + 10).toString())),
        ("+100", desciption.replaceFirst(regex, (number + 100).toString())),
        ("+500", desciption.replaceFirst(regex, (number + 500).toString())),
      ];
    }

    return [];
  }
}
