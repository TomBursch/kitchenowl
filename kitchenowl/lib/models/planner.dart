import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipePlan extends Model {
  final Recipe recipe;
  final DateTime? cookingDate;
  final int? yields;

  RecipePlan({
    required this.recipe,
    this.cookingDate,
    this.yields,
  });

  factory RecipePlan.fromJson(Map<String, dynamic> map) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(map["cooking_date"], isUtc: true);
    return RecipePlan(
      recipe: Recipe.fromJson(map['recipe']),
      cookingDate: DateTime.utc(date.year, date.month, date.day),
      yields: map['yields'],
    );
  }

  Recipe get recipeWithYields {
    if (yields == null || yields! <= 0) return recipe;
    return recipe.withYields(yields!);
  }

  @override
  List<Object?> get props => [recipe, cookingDate, yields];

  @override
  Map<String, dynamic> toJson() => {
        "recipe_id": recipe.id,
        if (cookingDate != null)
          "cooking_date": cookingDate?.millisecondsSinceEpoch,
        if (yields != null) "yields": yields,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "recipe": recipe.toJson(),
    });
}
