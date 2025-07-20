import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/recipe_discover_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/recipe_list_display_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/widgets/sliver_recipe_carousel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class RecipeDiscoverPage extends StatefulWidget {
  final Household household;

  const RecipeDiscoverPage({
    super.key,
    required this.household,
  });

  @override
  State<RecipeDiscoverPage> createState() => _RecipeDiscoverPageState();
}

class _RecipeDiscoverPageState extends State<RecipeDiscoverPage> {
  late final RecipeDiscoverCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeDiscoverCubit(widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HouseholdCubit(widget.household)),
        BlocProvider.value(value: cubit),
      ],
      child: Scaffold(
        body: BlocBuilder<RecipeDiscoverCubit, RecipeDiscoverState>(
            bloc: cubit,
            builder: (context, state) {
              if (state is RecipeDiscoverErrorState) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBar(
                      title:
                          Text(AppLocalizations.of(context)!.recipesDiscover),
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
              if (state.discover.isEmpty()) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppBar(
                      title:
                          Text(AppLocalizations.of(context)!.recipesDiscover),
                    ),
                    Spacer(),
                    Text(
                      AppLocalizations.of(context)!.recipeEmpty,
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                  ],
                );
              }
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    actions: [
                      KitchenowlSearchAnchor(
                        viewOnSubmitted: (query) =>
                            Navigator.of(context, rootNavigator: true)
                                .push(MaterialPageRoute(
                          builder: (context) => RecipeListDisplayPage(
                            title: query,
                            household:
                                cubit.state.household ?? widget.household,
                            showHousehold: true,
                            moreRecipes: (page) => ApiService.getInstance()
                                .searchAllRecipes(query, page,
                                    cubit.state.household?.language),
                          ),
                        )),
                        suggestionsBuilder: (
                          BuildContext context,
                          SearchController controller,
                        ) =>
                            state.discover.communityNewest
                                .map((e) => e.name)
                                .toList(),
                      ),
                      const SizedBox(width: 8),
                    ],
                    expandedHeight: 160,
                    flexibleSpace: FlexibleSpaceBar(
                      title:
                          Text(AppLocalizations.of(context)!.recipesDiscover),
                      background: Container(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer),
                    ),
                  ),
                  if (state.discover.popularTags.isNotEmpty)
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            "${AppLocalizations.of(context)!.tagsPopular}:",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ),
                  SliverCrossAxisConstrained(
                    maxCrossAxisExtent: 1600,
                    child: SliverToBoxAdapter(
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
                                    label:
                                        Text(state.discover.popularTags[i - 1]),
                                    onPressed: () => Navigator.of(context,
                                            rootNavigator: true)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecipeListDisplayPage(
                                          title:
                                              state.discover.popularTags[i - 1],
                                          household: cubit.state.household ??
                                              widget.household,
                                          showHousehold: true,
                                          moreRecipes: (page) =>
                                              ApiService.getInstance()
                                                  .searchAllRecipesByTag(
                                                      state.discover
                                                          .popularTags[i - 1],
                                                      page,
                                                      cubit.state.household
                                                          ?.language),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          itemCount: state.discover.popularTags.length + 1,
                        ),
                      ),
                    ),
                  ),
                  if (state.discover.curated.isNotEmpty)
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverRecipeCarousel(
                        recipes: state.discover.curated,
                        title:
                            "${AppLocalizations.of(context)!.recipesCurated}:",
                        showHousehold: true,
                        alwaysShowMoreAction: true,
                        isLoading: state is RecipeDiscoverLoadingState,
                        limit: getValueForScreenType(
                          context: context,
                          mobile: 5,
                          tablet: 5,
                          desktop: 10,
                        ),
                        cardWidth: getValueForScreenType(
                          context: context,
                          mobile: 300,
                          tablet: 325,
                          desktop: 325,
                        ),
                        showMore: () =>
                            Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => RecipeListDisplayPage(
                              title:
                                  AppLocalizations.of(context)!.recipesCurated,
                              household: widget.household,
                              recipes: state.discover.curated,
                              showHousehold: true,
                              moreRecipes: (page) => ApiService.getInstance()
                                  .discoverRecipesCurated(
                                      cubit.state.household?.language, page),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.discover.communityPopular.isNotEmpty)
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverRecipeCarousel(
                        recipes: state.discover.communityPopular,
                        title:
                            "${AppLocalizations.of(context)!.recipesPopular}:",
                        showHousehold: true,
                        alwaysShowMoreAction: true,
                        isLoading: state is RecipeDiscoverLoadingState,
                        limit: getValueForScreenType(
                          context: context,
                          mobile: 5,
                          tablet: 5,
                          desktop: 10,
                        ),
                        showMore: () =>
                            Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => RecipeListDisplayPage(
                              title:
                                  AppLocalizations.of(context)!.recipesPopular,
                              household: widget.household,
                              recipes: state.discover.communityPopular,
                              showHousehold: true,
                              moreRecipes: (page) => ApiService.getInstance()
                                  .discoverRecipesPopular(
                                      cubit.state.household?.language, page),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.discover.communityNewest.isNotEmpty)
                    SliverCrossAxisConstrained(
                      maxCrossAxisExtent: 1600,
                      child: SliverRecipeCarousel(
                        recipes: state.discover.communityNewest,
                        title:
                            "${AppLocalizations.of(context)!.recipesNewestCommunity}:",
                        showHousehold: true,
                        alwaysShowMoreAction: true,
                        isLoading: state is RecipeDiscoverLoadingState,
                        limit: getValueForScreenType(
                          context: context,
                          mobile: 5,
                          tablet: 5,
                          desktop: 10,
                        ),
                        showMore: () =>
                            Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => RecipeListDisplayPage(
                              title: AppLocalizations.of(context)!
                                  .recipesNewestCommunity,
                              household: widget.household,
                              recipes: state.discover.communityNewest,
                              showHousehold: true,
                              moreRecipes: (page) => ApiService.getInstance()
                                  .discoverRecipesNewest(
                                      cubit.state.household?.language, page),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
