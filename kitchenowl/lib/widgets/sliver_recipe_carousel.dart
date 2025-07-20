import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:kitchenowl/widgets/shimmer_recipe_card.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SliverRecipeCarousel extends StatelessWidget {
  final List<Recipe> recipes;
  final List<Widget> actions;
  final Future<void> Function(Recipe recipe)? onLongPressed;
  final Future<void> Function(Recipe recipe)? onAddToDate;
  final void Function(Recipe recipe)? onPressed;
  final String title;
  final void Function()? showMore;
  final bool alwaysShowMoreAction;
  final ScrollController? scrollController;
  final bool showHousehold;
  final bool isLoading;
  final int? limit;
  final double? cardWidth;
  final double? cardHeight;

  const SliverRecipeCarousel({
    super.key,
    required this.recipes,
    this.onLongPressed,
    this.onAddToDate,
    this.onPressed,
    this.actions = const [],
    required this.title,
    this.scrollController,
    this.showMore,
    this.alwaysShowMoreAction = false,
    this.showHousehold = false,
    this.isLoading = false,
    this.limit,
    this.cardWidth,
    this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        sliver: SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ...actions,
                if (showMore != null &&
                    (alwaysShowMoreAction ||
                        getValueForScreenType(
                          context: context,
                          mobile: false,
                          tablet: true,
                          desktop: true,
                        )) &&
                    recipes.length >= (limit ?? 0))
                  FilledButton.tonalIcon(
                    onPressed: showMore,
                    icon: Icon(Icons.keyboard_arrow_right_rounded),
                    iconAlignment: IconAlignment.end,
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(
                          EdgeInsets.fromLTRB(16, 8, 8, 8)),
                    ),
                    label: Text(AppLocalizations.of(context)!.more),
                  ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: cardHeight ??
              getValueForScreenType(
                context: context,
                mobile: 370,
                tablet: 405,
                desktop: 405,
              ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            controller: scrollController,
            itemBuilder: (context, i) {
              if (i ==
                  math.min(limit ?? recipes.length, recipes.length) +
                      (isLoading ? 1 : 0))
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 40,
                          child: Material(
                            type: MaterialType.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            child: InkWell(
                              child: Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                              customBorder: CircleBorder(),
                              onTap: showMore,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(AppLocalizations.of(context)!.more),
                      ],
                    ),
                  ),
                );
              if (i >= recipes.length) return ShimmerRecipeCard();
              return RecipeCard(
                key: ValueKey(recipes[i].id),
                recipe: recipes[i],
                onLongPressed: onLongPressed != null
                    ? () => onLongPressed!(recipes[i])
                    : null,
                onAddToDate:
                    onAddToDate != null ? () => onAddToDate!(recipes[i]) : null,
                onPressed:
                    onPressed != null ? () => onPressed!(recipes[i]) : null,
                showHousehold: showHousehold,
                width: cardWidth,
              );
            },
            itemCount: math.min(limit ?? recipes.length, recipes.length) +
                (showMore != null && recipes.length >= (limit ?? 0) ? 1 : 0) +
                (isLoading ? 1 : 0),
            scrollDirection: Axis.horizontal,
          ),
        ),
      ),
    ]);
  }
}
