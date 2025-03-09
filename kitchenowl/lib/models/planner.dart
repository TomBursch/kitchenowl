import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/recipe.dart';

final datetime_min = DateTime(1, 1, 1);

DateTime nextWeekday(int targetWeekday) {
  DateTime now = DateTime.now();
  
  int currentWeekday = now.weekday - 1;

  // Calculate the difference
  int daysToAdd = (targetWeekday - currentWeekday) % 6;
  if (daysToAdd < 0) {
    daysToAdd += 7; // Move to the next week if the target day is today or in the past
  }

  // Return the next possible DateTime for the target weekday
  return now.add(Duration(days: daysToAdd));
}
DateTime toEndOfDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
}


class RecipePlan extends Model {
  final Recipe recipe;
  final DateTime? cooking_date; // privat gemacht
  final int? _day;
  final int? yields;

  RecipePlan({
    required this.recipe,
    this.cooking_date, // Parameter umbenennen
    this.yields,
  }) : _day = cooking_date != null ? cooking_date.weekday : null; 

  int? get day => _day;

  factory RecipePlan.fromJson(Map<String, dynamic> map) {
    DateTime? _cooking_date;
    if (map.containsKey("day") && map['day'] != null) {
      if (map['day'] == -1) {
        _cooking_date = datetime_min;
      } else {
        _cooking_date = toEndOfDay(nextWeekday(map['day'])); 
      }
    }
    if (map.containsKey("cooking_date")) {
      _cooking_date = DateTime.fromMillisecondsSinceEpoch(map["cooking_date"], isUtc: true); 
    }
    return RecipePlan(
      recipe: Recipe.fromJson(map['recipe']),
      cooking_date: _cooking_date,
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
        "cooking_date":  cooking_date?.toIso8601String(),
        if (yields != null) "yields": yields,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "recipe": recipe.toJson(),
    });
}
