import 'package:kitchenowl/models/model.dart';

class ImportSettings extends Model {
  final bool items;
  final bool recipes;
  final bool recipesOverwrite;
  final bool expenses;
  final bool shoppinglists;

  const ImportSettings({
    this.items = false,
    this.recipes = true,
    this.recipesOverwrite = false,
    this.expenses = false,
    this.shoppinglists = false,
  });

  ImportSettings copyWith({
    bool? items,
    bool? recipes,
    bool? recipesOverwrite,
    bool? expenses,
    bool? shoppinglists,
  }) =>
      ImportSettings(
        items: items ?? this.items,
        recipes: recipes ?? this.recipes,
        recipesOverwrite: recipesOverwrite ?? this.recipesOverwrite,
        expenses: expenses ?? this.expenses,
        shoppinglists: shoppinglists ?? this.shoppinglists,
      );

  @override
  List<Object?> get props => [
        items,
        recipes,
        recipesOverwrite,
        expenses,
        shoppinglists,
      ];

  @override
  Map<String, dynamic> toJson() => {
        "items": items,
        "recipes": recipes,
        "recipes_overwrite": recipesOverwrite,
        "expenses": expenses,
        "shoppinglists": shoppinglists,
      };
}
