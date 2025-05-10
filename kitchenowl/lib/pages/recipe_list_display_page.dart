import 'package:flutter/material.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RecipeListDisplayPage extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;

  const RecipeListDisplayPage({
    super.key,
    required this.title,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(title),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverCrossAxisConstrained(
              maxCrossAxisExtent: 1600,
              child: SliverGrid.builder(
                itemCount: recipes.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, i) => RecipeCard(
                  key: Key(recipes[i].name),
                  recipe: recipes[i],
                  //onUpdated: cubit.refresh,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
