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
                            state.communityNewest.map((e) => e.name).toList(),
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
                  if (state.tags.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "${AppLocalizations.of(context)!.tagsPopular}:",
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
                                  onPressed: () =>
                                      Navigator.of(context, rootNavigator: true)
                                          .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RecipeListDisplayPage(
                                        title: state.tags[i - 1],
                                        household: cubit.state.household ??
                                            widget.household,
                                        showHousehold: true,
                                        moreRecipes: (page) =>
                                            ApiService.getInstance()
                                                .searchAllRecipesByTag(
                                                    state.tags[i - 1],
                                                    page,
                                                    cubit.state.household
                                                        ?.language),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        itemCount: state.tags.length + 1,
                      ),
                    ),
                  ),
                  SliverRecipeCarousel(
                    recipes: state.communityNewest,
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
                          recipes: state.communityNewest,
                          showHousehold: true,
                          moreRecipes: (page) => ApiService.getInstance()
                              .suggestRecipesNewest(
                                  cubit.state.household?.language, page),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }
}
