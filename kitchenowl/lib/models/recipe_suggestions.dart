import 'package:equatable/equatable.dart';
import 'package:kitchenowl/models/recipe.dart';

class RecipeDiscover extends Equatable {
  final Recipe? featured;
  final List<String> popularTags;
  final List<Recipe> curated;
  final List<Recipe> communityPopular;
  final List<Recipe> communityNewest;

  const RecipeDiscover({
    this.featured,
    this.popularTags = const [],
    this.curated = const [],
    this.communityPopular = const [],
    this.communityNewest = const [],
  });

  factory RecipeDiscover.fromJson(Map<String, dynamic> map) => RecipeDiscover(
        popularTags: List<String>.from(map["popular_tags"]),
        curated: (map["curated"] as List<dynamic>)
            .map((e) => Recipe.fromJson(e))
            .toList(),
        communityPopular: (map["popular"] as List<dynamic>)
            .map((e) => Recipe.fromJson(e))
            .toList(),
        communityNewest: (map["newest"] as List<dynamic>)
            .map((e) => Recipe.fromJson(e))
            .toList(),
      );

  @override
  List<Object?> get props => [
        featured,
        popularTags,
        curated,
        communityPopular,
        communityNewest,
      ];
}
