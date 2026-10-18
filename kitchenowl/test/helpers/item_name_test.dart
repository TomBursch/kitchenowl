import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/helpers/item_name.dart';

void main() {
  test("Normalizing lowers case", () {
    expect(normalizeItemName("Milk"), "milk");
    expect(normalizeItemName("MILK"), "milk");
  });

  test("Normalizing removes diacritics", () {
    expect(normalizeItemName("Äpple"), "apple");
    expect(normalizeItemName("Crème fraîche"), "creme fraiche");
    expect(normalizeItemName("Jalapeño"), "jalapeno");
    expect(normalizeItemName("Ål"), "al");
    expect(normalizeItemName("Öl"), "ol");
  });

  test("Normalizing spells out ligatures", () {
    expect(normalizeItemName("Œuf"), "oeuf");
    expect(normalizeItemName("œuf"), "oeuf");
    expect(normalizeItemName("Ærter"), "aerter");
    expect(normalizeItemName("Weißwurst"), "weisswurst");
    expect(normalizeItemName("WEIẞWURST"), "weisswurst");
    expect(normalizeItemName("Smør"), "smor");
  });

  test("Comparing ignores case and diacritics", () {
    expect(compareItemNames("Äpple", "Banana"), lessThan(0));
    expect(compareItemNames("apple", "Äpple"), isNot(0));
    expect(compareItemNames("Œuf", "Orange"), lessThan(0));
    expect(compareItemNames("Zucchini", "äpple"), greaterThan(0));
  });
}
