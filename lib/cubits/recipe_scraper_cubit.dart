import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/recipe_scrape.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class RecipeScraperCubit extends Cubit<RecipeScraperState> {
  final String url;

  RecipeScraperCubit(this.url) : super(RecipeScraperLoadingState()) {
    scrapeRecipe();
  }

  Future<void> scrapeRecipe() async {
    final res = await ApiService.getInstance().scrapeRecipe(url);

    if (res != null) {
      emit(RecipeScraperLoadedState.fromScrape(res));
    } else {
      emit(RecipeScraperErrorState());
    }
  }

  bool hasValidRecipe() {
    return state is RecipeScraperLoadedState &&
        (state as RecipeScraperLoadedState).isValid();
  }

  Recipe? getRecipe() {
    if (!hasValidRecipe()) return null;

    return (state as RecipeScraperLoadedState).recipe.copyWith(
          items: (state as RecipeScraperLoadedState)
              .items
              .values
              .where((e) => e != null)
              .cast<RecipeItem>()
              .toList(),
        );
  }
}

abstract class RecipeScraperState extends Equatable {
  const RecipeScraperState();

  @override
  List<Object?> get props => [];
}

class RecipeScraperLoadingState extends RecipeScraperState {}

class RecipeScraperErrorState extends RecipeScraperState {}

class RecipeScraperLoadedState extends RecipeScraperState {
  final Recipe recipe;
  final Map<String, RecipeItem?> items;

  const RecipeScraperLoadedState({
    required this.recipe,
    required this.items,
  });

  RecipeScraperLoadedState.fromScrape(RecipeScrape scrape)
      : recipe = scrape.recipe,
        items = scrape.items;

  RecipeScraperLoadedState copyWith({
    Recipe? recipe,
    Map<String, RecipeItem?>? items,
  }) =>
      RecipeScraperLoadedState(
        recipe: recipe ?? this.recipe,
        items: items ?? this.items,
      );

  bool isValid() => false;

  @override
  List<Object?> get props => [recipe, items];
}
