import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/helpers/recipe_item_markdown_extension.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  test('parses Unicode recipe item names', () {
    const recipe = Recipe(
      items: [
        RecipeItem(name: 'Crème fraîche'),
        RecipeItem(name: '豆腐'),
      ],
    );
    final document = md.Document(
      inlineSyntaxes: [RecipeExplicitItemMarkdownSyntax(recipe)],
    );

    final nodes = document.parseLines([
      '@crème_fraîche{200 g} and @豆腐',
    ]);
    final paragraph = nodes.single as md.Element;
    final recipeItems = paragraph.children!
        .whereType<md.Element>()
        .where((element) => element.tag == 'recipeItem')
        .toList();

    expect(recipeItems.map((element) => element.textContent), [
      'crème fraîche',
      '豆腐',
    ]);
    expect(recipeItems.first.attributes['description'], '200 g');
  });
}
