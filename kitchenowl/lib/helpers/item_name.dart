import 'package:diacritic/diacritic.dart';

String normalizeItemName(String name) =>
    // removeDiacritics maps ß to a single s
    removeDiacritics(name.toLowerCase().replaceAll('ß', 'ss'));

int compareItemNames(String a, String b) {
  final int result = normalizeItemName(a).compareTo(normalizeItemName(b));
  if (result != 0) return result;
  // List.sort is not stable, so break ties for a fixed order
  return a.compareTo(b);
}
