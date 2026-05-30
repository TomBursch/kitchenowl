class RecipeImportPreview {
  final String token;
  final List<RecipeImportRecipe> recipes;
  final List<RecipeImportDuplicate> duplicates;
  final Map<String, RecipeImportDuplicate> _duplicatesByImportId;

  RecipeImportPreview({
    required this.token,
    required List<RecipeImportRecipe> recipes,
    required List<RecipeImportDuplicate> duplicates,
  })  : recipes = List.unmodifiable(recipes),
        duplicates = List.unmodifiable(duplicates),
        _duplicatesByImportId = Map.unmodifiable({
          for (final duplicate in duplicates)
            if (duplicate.importId.isNotEmpty) duplicate.importId: duplicate,
        });

  bool get hasDuplicates => duplicates.isNotEmpty;

  RecipeImportDuplicate? duplicateFor(String importId) {
    return _duplicatesByImportId[importId];
  }

  factory RecipeImportPreview.fromJson(Map<String, dynamic> json) {
    final recipes = <RecipeImportRecipe>[];
    for (final entry in json['recipes'] as List? ?? const []) {
      if (entry is Map) {
        recipes.add(
          RecipeImportRecipe.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    final duplicates = <RecipeImportDuplicate>[];
    for (final entry in json['duplicates'] as List? ?? const []) {
      if (entry is Map) {
        duplicates.add(
          RecipeImportDuplicate.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    return RecipeImportPreview(
      token: json['token']?.toString() ?? '',
      recipes: recipes,
      duplicates: duplicates,
    );
  }
}

class RecipeImportRecipe {
  final String importId;
  final String name;
  final String source;

  const RecipeImportRecipe({
    required this.importId,
    required this.name,
    required this.source,
  });

  factory RecipeImportRecipe.fromJson(Map<String, dynamic> json) {
    return RecipeImportRecipe(
      importId: json['import_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}

class RecipeImportDuplicate {
  final String importId;
  final int? recipeId;
  final String recipeName;

  const RecipeImportDuplicate({
    required this.importId,
    required this.recipeId,
    required this.recipeName,
  });

  factory RecipeImportDuplicate.fromJson(Map<String, dynamic> json) {
    return RecipeImportDuplicate(
      importId: json['import_id']?.toString() ?? '',
      recipeId: _parseRecipeId(json['recipe_id']),
      recipeName: json['recipe_name']?.toString() ?? '',
    );
  }
}

int? _parseRecipeId(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
