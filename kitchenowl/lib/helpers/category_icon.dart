import 'package:flutter/material.dart';

/// Extracts the leading emoji from a category name (e.g. "🥛 Dairy" -> "🥛").
/// Categories are conventionally named with a leading emoji; returns null
/// when no leading emoji is present.
String? categoryEmoji(String? categoryName) {
  if (categoryName == null || categoryName.isEmpty) return null;
  final runeIterator = categoryName.runes.iterator;
  if (!runeIterator.moveNext()) return null;

  // Emoji are outside the Basic Multilingual Plane (U+1F300+) or in
  // misc. symbol ranges; consume all leading emoji-ish runes (incl.
  // variation selectors / ZWJ sequences) and stop at the first
  // letter/digit/space-with-more-text.
  final buffer = StringBuffer();
  int? firstRune;
  while (true) {
    final rune = runeIterator.current;
    firstRune ??= rune;
    final isEmojiish = rune >= 0x1F000 ||
        (rune >= 0x2190 && rune <= 0x27BF) ||
        (rune >= 0xFE00 && rune <= 0xFE0F) || // variation selectors
        rune == 0x200D || // ZWJ
        rune == 0x20E3; // combining enclosing keycap
    if (!isEmojiish) break;
    buffer.writeCharCode(rune);
    if (!runeIterator.moveNext()) break;
  }

  final result = buffer.toString();
  if (result.isEmpty) return null;
  // Ignore stray symbols that aren't really emoji categories
  if (firstRune < 0x1F000 && firstRune < 0x2190) return null;
  return result;
}

/// Leading widget for an item line: the item's own icon when set, otherwise
/// (when enabled) the emoji of the item's category, otherwise null.
Widget? categoryBadgeLeading({
  required IconData? itemIcon,
  required String? categoryName,
  required bool showCategoryIcon,
  required Color color,
  double size = 24,
}) {
  if (itemIcon != null) {
    return Icon(itemIcon, color: color, size: size);
  }
  final emoji = showCategoryIcon ? categoryEmoji(categoryName) : null;
  if (emoji == null) return null;
  return Text(
    emoji,
    style: TextStyle(fontSize: size * 0.8, color: color),
    maxLines: 1,
  );
}
