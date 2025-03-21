import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/recipe.dart';

final datetime_min = DateTime(1, 1, 1);

DateTime toEndOfDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
}


class RecipePlan extends Model {
  final Recipe recipe;
  final DateTime? cooking_date; // privat gemacht
  final int? yields;

  RecipePlan({
    required this.recipe,
    this.cooking_date, // Parameter umbenennen
    this.yields,
  }); 

  factory RecipePlan.fromJson(Map<String, dynamic> map) {
    return RecipePlan(
      recipe: Recipe.fromJson(map['recipe']),
      cooking_date: DateTime.fromMillisecondsSinceEpoch(map["cooking_date"], isUtc: true),
      yields: map['yields'],
    );
  }
  

  Recipe get recipeWithYields {
    if (yields == null || yields! <= 0) return recipe;
    return recipe.withYields(yields!);
  }

  @override
  List<Object?> get props => [recipe, cooking_date, yields];

  @override
  Map<String, dynamic> toJson() => {
        "recipe_id": recipe.id,
        if (cooking_date != null) "cooking_date":  cooking_date?.toIso8601String(),
        if (yields != null) "yields": yields,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "recipe": recipe.toJson(),
    });
}
