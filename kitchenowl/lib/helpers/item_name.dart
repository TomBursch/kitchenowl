import 'package:diacritic/diacritic.dart';

const Map<String, String> _ligatures = {
  'æ': 'ae',
  'œ': 'oe',
  'ĳ': 'ij',
  'ø': 'o',
  'ß': 'ss',
  'ð': 'd',
  'þ': 'th',
  'ł': 'l',
  'đ': 'd',
  'ħ': 'h',
  'ŧ': 't',
  'ǥ': 'g',
  'ƀ': 'b',
  'ŋ': 'ng',
  'ı': 'i',
  'ĸ': 'k',
  'ŉ': 'n',
  'ƕ': 'hv',
  'ƣ': 'oi',
  'ȣ': 'ou',
  'ə': 'e',
};

final RegExp _ligatureRegex = RegExp(
  '[${_ligatures.keys.join()}]',
);

String normalizeItemName(String name) {
  // 1. Strip diacritics first (handles 'ǽ' -> 'æ', 'İ' -> 'I', 'ﬁ' -> 'fi')
  // 2. Lowercase everything ('Æ' -> 'æ', 'ẞ' -> 'ß')
  final lowered = removeDiacritics(name).toLowerCase();

  // 3. Expand any remaining ligatures in a single pass
  return lowered.replaceAllMapped(
    _ligatureRegex,
    (match) => _ligatures[match.group(0)!]!,
  );
}

int compareItemNames(String a, String b) {
  final int result = normalizeItemName(a).compareTo(normalizeItemName(b));
  if (result != 0) return result;
  // List.sort is not stable, so break ties for a fixed order
  return a.compareTo(b);
}
