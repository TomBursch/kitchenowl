import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_about_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/recipe_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HouseholdAboutPage extends StatefulWidget {
  final Household household;

  const HouseholdAboutPage({super.key, required this.household});

  @override
  State<HouseholdAboutPage> createState() => _HouseholdAboutPageState();
}

class _HouseholdAboutPageState extends State<HouseholdAboutPage> {
  final ScrollController scrollController = ScrollController();
  late HouseholdAboutCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = HouseholdAboutCubit(widget.household);
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
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<HouseholdAboutCubit, HouseholdAboutState>(
        bloc: cubit,
        builder: (context, state) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 1600,
              child: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: HouseholdCircleAvatar(
                          household: state.household,
                          radius: 45,
                          textScaler: TextScaler.linear(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              state.household.name,
                              style: TextTheme.of(context).displaySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (state.household.verified)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (state.household.description?.isNotEmpty ?? false)
                        Text(
                          state.household.description!,
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      if (state.household.link != null &&
                          state.household.link!.isNotEmpty &&
                          isValidUrl(state.household.link!))
                        ListTile(
                          title: Text(state.household.link!),
                          leading: Icon(Icons.link),
                          onTap: () => openUrl(context, state.household.link!),
                        ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
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
                      maxCrossAxisExtent: 350,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, i) => RecipeCard(
                      key: Key(state.recipes[i].name),
                      recipe: state.recipes[i],
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
    );
  }

  void _scrollListen() {
    if ((scrollController.position.pixels ==
        scrollController.position.maxScrollExtent)) {
      cubit.loadMore();
    }
  }
}
