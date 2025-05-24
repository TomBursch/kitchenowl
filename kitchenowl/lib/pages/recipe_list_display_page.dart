import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/recipe_list_display_cubit.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RecipeListDisplayPage extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;
  final LoadMoreRecipes? moreRecipes;
  final bool showHousehold;
  final List<Widget> Function(
      RecipeListDisplayCubit cubit, ScrollController controller)? actions;

  const RecipeListDisplayPage({
    super.key,
    required this.title,
    required this.recipes,
    this.showHousehold = false,
    this.moreRecipes,
    this.actions,
  });

  @override
  State<RecipeListDisplayPage> createState() => _RecipeListDisplayPageState();
}

class _RecipeListDisplayPageState extends State<RecipeListDisplayPage> {
  final ScrollController scrollController = ScrollController();
  late final RecipeListDisplayCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeListDisplayCubit(
      initialRecipes: widget.recipes,
      moreRecipes: widget.moreRecipes,
    );
    scrollController.addListener(_scrollListen);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListen);
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(widget.title),
              actions: widget.actions != null
                  ? widget.actions!(cubit, scrollController)
                  : null,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver:
                  BlocBuilder<RecipeListDisplayCubit, RecipeListDisplayState>(
                bloc: cubit,
                builder: (context, state) => SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 1600,
                  child: SliverGrid.builder(
                    itemCount: state.recipes.length,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: widget.showHousehold ? 420 : 350,
                      childAspectRatio: widget.showHousehold ? 0.75 : 0.8,
                    ),
                    itemBuilder: (context, i) => RecipeCard(
                      key: Key(state.recipes[i].name),
                      recipe: state.recipes[i],
                      showHousehold: widget.showHousehold,
                      onUpdated: cubit.refresh,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollListen() {
    if ((scrollController.position.pixels ==
        scrollController.position.maxScrollExtent)) {
      cubit.loadMore();
    }
  }
}
