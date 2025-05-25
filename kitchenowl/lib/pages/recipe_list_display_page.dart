import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/recipe_list_display_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RecipeListDisplayPage extends StatefulWidget {
  final Household? household;
  final String title;
  final List<Recipe>? recipes;
  final LoadMoreRecipes? moreRecipes;
  final bool showHousehold;
  final List<Widget> Function(
      RecipeListDisplayCubit cubit, ScrollController controller)? actions;

  const RecipeListDisplayPage({
    super.key,
    required this.title,
    this.household,
    this.recipes,
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        if (widget.household != null)
          BlocProvider(create: (context) => HouseholdCubit(widget.household!))
      ],
      child: Scaffold(
        body: BlocBuilder<RecipeListDisplayCubit, RecipeListDisplayState>(
          bloc: cubit,
          builder: (context, state) => CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(widget.title),
                actions: widget.actions != null
                    ? widget.actions!(cubit, scrollController)
                    : null,
              ),
              if (state.loadedPages <= 0)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (state.loadedPages > 0 && state.recipes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.no_food_rounded),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.recipeEmptySearch),
                      ],
                    ),
                  ),
                ),
              if (state.recipes.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverCrossAxisConstrained(
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
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
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
