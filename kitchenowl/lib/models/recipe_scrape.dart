import 'package:equatable/equatable.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';

enum RecipeScrapeStatus {
  fetchingWebsite,
  scrapingRecipe,
  detectingIngredients,
  detectingIngredientsAi,
  usingAi;

  bool get isUsingAi =>
      this == RecipeScrapeStatus.usingAi ||
      this == RecipeScrapeStatus.detectingIngredientsAi;

  static RecipeScrapeStatus? fromString(String? value) => switch (value) {
        'fetching_website' => RecipeScrapeStatus.fetchingWebsite,
        'scraping_recipe' => RecipeScrapeStatus.scrapingRecipe,
        'detecting_ingredients' => RecipeScrapeStatus.detectingIngredients,
        'detecting_ingredients_ai' => RecipeScrapeStatus.detectingIngredientsAi,
        'using_ai' => RecipeScrapeStatus.usingAi,
        _ => null,
      };
}

sealed class RecipeScrapeEvent extends Equatable {
  const RecipeScrapeEvent();

  @override
  List<Object?> get props => [];
}

class RecipeScrapeStatusEvent extends RecipeScrapeEvent {
  final RecipeScrapeStatus status;

  const RecipeScrapeStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class RecipeScrapeDoneEvent extends RecipeScrapeEvent {
  final RecipeScrape scrape;

  const RecipeScrapeDoneEvent(this.scrape);

  @override
  List<Object?> get props => [scrape];
}

class RecipeScrapeErrorEvent extends RecipeScrapeEvent {
  final int statusCode;
  final String? message;

  const RecipeScrapeErrorEvent(this.statusCode, [this.message]);

  @override
  List<Object?> get props => [statusCode, message];
}

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
