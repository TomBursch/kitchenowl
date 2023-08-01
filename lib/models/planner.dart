import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipePlan extends Model {
  final Recipe recipe;
  final int? day;
  final int? yields;

  const RecipePlan({
    required this.recipe,
    this.day,
    this.yields,
  });

  factory RecipePlan.fromJson(Map<String, dynamic> map) {
    return RecipePlan(
      recipe: Recipe.fromJson(map['recipe']),
      day: map['day'],
      yields: map['yields'],
    );
  }

  Recipe get recipeWithYields {
    if (yields == null || yields! <= 0) return recipe;

    return recipe.withYields(yields!);
  }

  @override
  List<Object?> get props => [recipe, day, yields];

  @override
  Map<String, dynamic> toJson() => {
        "recipe_id": recipe.id,
        if (day != null) "day": day,
        if (yields != null) "yields": yields,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "recipe": recipe.toJson(),
    });
}
