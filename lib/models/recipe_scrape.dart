import 'package:equatable/equatable.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipeScrape extends Equatable {
  final Recipe recipe;
  final Map<String, RecipeItem?> items;

  const RecipeScrape({
    required this.recipe,
    required this.items,
  });

  factory RecipeScrape.fromJson(Map<String, dynamic> map) => RecipeScrape(
        recipe: Recipe.fromJson(map['recipe']),
        items: (map['items'] as Map<String, dynamic>).map<String, RecipeItem?>(
          (key, value) =>
              MapEntry(key, value != null ? RecipeItem.fromJson(value) : null),
        ),
      );

  @override
  List<Object?> get props => [recipe, items];
}
