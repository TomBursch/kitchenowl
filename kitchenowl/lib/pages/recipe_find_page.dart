import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/reciep_find_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/recipe_list_display_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/sliver_recipe_carousel.dart';

class RecipeFindPage extends StatefulWidget {
  final Household? household;

  const RecipeFindPage({
    super.key,
    this.household,
  });

  @override
  State<RecipeFindPage> createState() => _RecipeFindPageState();
}

class _RecipeFindPageState extends State<RecipeFindPage> {
  late final RecipeFindCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeFindCubit(widget.household);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HouseholdCubit(widget.household!),
      child: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: BlocBuilder<RecipeFindCubit, RecipeFindState>(
              bloc: cubit,
              builder: (context, state) {
                if (state is RecipeFindErrorState) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppBar(
                        title: Text("Find Recipes"), // TODO l10n
                      ),
                      Spacer(),
                      Text(
                        AppLocalizations.of(context)!.error,
                        textAlign: TextAlign.center,
                      ),
                      Spacer(),
                    ],
                  );
                }
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: Text("Find Recipes"), // TODO l10n
                      pinned: true,
                      actions: [
                        KitchenowlSearchAnchor(
                          onSearch: (s) {},
                          suggestionsBuilder: (
                            BuildContext context,
                            SearchController controller,
                          ) =>
                              List.generate(5, (int index) => 'item $index'),
                        ),
                      ],
                    ),
                    if (state.tags.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            "Popular Tags:", // TODO l10n
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 28,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) => i == 0
                              ? const SizedBox(width: 8)
                              : Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ActionChip(
                                    label: Text(state.tags[i - 1]),
                                    onPressed: () {},
                                  ),
                                ),
                          itemCount: state.tags.length + 1,
                        ),
                      ),
                    ),
                    SliverRecipeCarousel(
                      recipes: state.communityNewest,
                      title: "Newest Community Recipes:", // TODO l10n
                      showHousehold: true,
                      isLoading: state is RecipeFindLoadingState,
                      limit: 5, // TODO adapt to screen size
                      showMore: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => RecipeListDisplayPage(
                            title: "Newest Community Recipes:",
                            recipes: state.communityNewest,
                            showHousehold: true,
                            moreRecipes: (page) => ApiService.getInstance()
                                .suggestRecipesNewest(
                                    cubit.household?.language, page),
                          ),
                        ),
                      ),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
