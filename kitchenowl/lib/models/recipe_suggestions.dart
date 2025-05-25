import 'package:equatable/equatable.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipeSuggestions extends Equatable {
  final Recipe? featured;
  final List<String> popularTags;
  final List<Recipe> communityNewest;

  const RecipeSuggestions({
    this.featured,
    required this.popularTags,
    required this.communityNewest,
  });

  factory RecipeSuggestions.fromJson(
          Map<String, dynamic> map) =>
      RecipeSuggestions(
          popularTags: List<String>.from(map["popular_tags"]),
          communityNewest: (map["newest"] as List<dynamic>)
              .map((e) => Recipe.fromJson(e))
              .toList());

  @override
  List<Object?> get props => [featured, popularTags, communityNewest];
}
