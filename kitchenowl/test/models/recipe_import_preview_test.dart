import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/models/recipe_import_preview.dart';

void main() {
  test('RecipeImportPreview fromJson skips malformed list entries', () {
    final preview = RecipeImportPreview.fromJson({
      'token': 'preview-token',
      'recipes': [
        null,
        'invalid',
        {
          'import_id': 'import-1',
          'name': 'Soup',
          'source': 'https://example.test/soup',
        },
      ],
      'duplicates': [
        123,
        {
          'import_id': 'import-1',
          'recipe_id': '42',
          'recipe_name': 'Soup',
        },
        {
          'import_id': 'import-2',
          'recipe_name': 'Pasta',
        },
      ],
    });

    expect(preview.token, 'preview-token');
    expect(preview.recipes, hasLength(1));
    expect(preview.recipes.single.importId, 'import-1');
    expect(preview.duplicates, hasLength(2));
    expect(preview.duplicates.first.recipeId, 42);
    expect(preview.duplicates.last.recipeId, isNull);
  });

  test('RecipeImportPreview duplicate lookup uses indexed access', () {
    final preview = RecipeImportPreview(
      token: 'token',
      recipes: const [],
      duplicates: const [
        RecipeImportDuplicate(
          importId: 'import-1',
          recipeId: 7,
          recipeName: 'Soup',
        ),
      ],
    );

    expect(preview.hasDuplicates, isTrue);
    expect(preview.duplicateFor('import-1')?.recipeId, 7);
    expect(preview.duplicateFor('missing'), isNull);
  });

  test('RecipeImportPreview fromJson tolerates missing keys', () {
    final preview = RecipeImportPreview.fromJson({
      'recipes': [
        {
          'import_id': 'import-1',
        },
      ],
      'duplicates': [
        {
          'import_id': 'import-2',
        },
      ],
    });

    expect(preview.token, isEmpty);
    expect(preview.recipes.single.name, isEmpty);
    expect(preview.recipes.single.source, isEmpty);
    expect(preview.duplicates.single.recipeId, isNull);
    expect(preview.duplicates.single.recipeName, isEmpty);
  });
}