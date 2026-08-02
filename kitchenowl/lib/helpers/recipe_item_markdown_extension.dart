import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:fraction/fraction.dart';
import 'package:kitchenowl/cubits/recipe_cubit.dart';
import 'package:kitchenowl/helpers/string_scaler.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/item_chip.dart';
import 'package:markdown/markdown.dart' as md;

class RecipeItemMarkdownBuilder extends MarkdownElementBuilder {
  final List<RecipeItem> items;
  final Fraction? itemScaledFactor;

  RecipeItemMarkdownBuilder({required this.items, this.itemScaledFactor});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if ((parentStyle?.fontSize ?? 0) > 14) return null;

    RecipeItem item = items.firstWhere(
      (e) => e.name.toLowerCase() == element.textContent,
    );
    String? overridenDescription = element.attributes["description"];
    if (overridenDescription != null && itemScaledFactor != null) {
      overridenDescription =
          StringScaler.scale(overridenDescription, itemScaledFactor!);
    }
    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: ItemChip(
            item: item,
            description: overridenDescription,
          ),
        ),
      ]),
    );
  }
}

class RecipeCubitItemMarkdownBuilder extends MarkdownElementBuilder {
  final RecipeCubit cubit;

  RecipeCubitItemMarkdownBuilder({required this.cubit});

  String cleanItemName(String name) {
    return name.toLowerCase().replaceAll(
        RegExp(r"""\n|\.|\(|\)|\\|\/|\?|\*|\+|,|!|%|$|#|@|^|;|:|"|=|~|{"""),
        "");
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if ((parentStyle?.fontSize ?? 0) > 14) return null;

    return RichText(
      text: TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: BlocBuilder<RecipeCubit, RecipeState>(
            bloc: cubit,
            buildWhen: (previous, current) =>
                previous.dynamicRecipe.items.firstWhere(
                      (e) => cleanItemName(e.name) == element.textContent,
                    ) !=
                    current.dynamicRecipe.items.firstWhere(
                      (e) => cleanItemName(e.name) == element.textContent,
                    ) ||
                previous.selectedYields != current.selectedYields,
            builder: (context, state) {
              RecipeItem item = state.dynamicRecipe.items.firstWhere(
                (e) => cleanItemName(e.name) == element.textContent,
              );

              String? overridenDescription = element.attributes["description"];
              if (overridenDescription != null &&
                  state.recipe.yields != 0 &&
                  state.selectedYields != null &&
                  state.recipe.yields != state.selectedYields) {
                overridenDescription = StringScaler.scale(overridenDescription,
                    Fraction(state.selectedYields!, state.recipe.yields));
              }

              return ItemChip(
                item: item,
                description: overridenDescription,
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Common grammatical suffixes that an LLM might append to (or omit from) an
/// ingredient name due to declension/plural inflection. Used by
/// [resolveRecipeItemName] so that e.g. an `@Lachsfilets` pill still matches
/// an item registered as "Lachsfilet".
const List<String> _kInflectionSuffixes = <String>[
  "nen",
  "ern",
  "en",
  "es",
  "er",
  "ie",
  "n",
  "s",
  "e",
];

/// Returns the cleaned name of the recipe item matching [input] (already
/// lower-cased and stripped of underscores), or `null` if no item matches.
///
/// Match order: exact, then `input` with a common suffix stripped (handles
/// inflected pill like `@Lachsfilets` for item "Lachsfilet"), then `input`
/// with a common suffix appended (handles bare-singular pill like
/// `@Tomate` for item "Tomaten").
String? resolveRecipeItemName(
  String input,
  Iterable<String> normalizedItemNames,
) {
  final names = normalizedItemNames.toSet();
  if (names.contains(input)) return input;

  // Don't strip suffixes from very short tokens to avoid false positives.
  if (input.length > 3) {
    for (final suffix in _kInflectionSuffixes) {
      if (input.length > suffix.length + 2 && input.endsWith(suffix)) {
        final stripped = input.substring(0, input.length - suffix.length);
        if (names.contains(stripped)) return stripped;
      }
    }
  }

  for (final suffix in _kInflectionSuffixes) {
    final extended = input + suffix;
    if (names.contains(extended)) return extended;
  }

  return null;
}

String _normalizeItemName(String name) {
  return name.toLowerCase().replaceAll(
      RegExp(r"""[\n.()\\/?\*+,!%$#@^;:"=~{]"""), "");
}

class RecipeExplicitItemMarkdownSyntax extends md.InlineSyntax {
  final Recipe recipe;

  RecipeExplicitItemMarkdownSyntax(this.recipe)
      : super(
          r"$^",
          startCharacter: 0x40,
        );

  static const String _pattern = r"""@([\p{L}_]+)(\{([^}]*)\})?""";

  @override
  final RegExp pattern = RegExp(
    _pattern,
    multiLine: true,
    caseSensitive: false,
    unicode: true,
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match[1]!.replaceAll("_", " ").trim().toLowerCase();
    final resolved = resolveRecipeItemName(
      name,
      recipe.items.map((e) => _normalizeItemName(e.name)),
    );
    if (resolved == null) {
      parser.advanceBy(1);

      return false;
    }

    final node = md.Element.text('recipeItem', resolved);
    if (match.group(3) != null)
      node.attributes["description"] = match.group(3)!;
    parser.addNode(node);

    return true;
  }
}
