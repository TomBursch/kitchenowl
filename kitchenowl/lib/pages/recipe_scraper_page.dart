import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/recipe_scraper_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/recipe_add_update_page.dart';
import 'package:kitchenowl/widgets/string_item_match.dart';

class RecipeScraperPage extends StatefulWidget {
  final String url;
  final Household household;

  const RecipeScraperPage({
    super.key,
    required this.url,
    required this.household,
  });

  @override
  _RecipeScraperPageState createState() => _RecipeScraperPageState();
}

class _RecipeScraperPageState extends State<RecipeScraperPage> {
  late RecipeScraperCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = RecipeScraperCubit(widget.household, widget.url);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HouseholdCubit(widget.household),
      child: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<RecipeScraperCubit, RecipeScraperState>(
          bloc: cubit,
          builder: (context, state) {
            if (state is! RecipeScraperLoadedState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    Uri.tryParse(widget.url)?.host ?? widget.url,
                    overflow: TextOverflow.fade,
                  ),
                ),
                body: Center(
                  child: state is RecipeScraperErrorState
                      ? Text(AppLocalizations.of(context)!.error)
                      : state is RecipeScraperUnsupportedState
                          ? Text(AppLocalizations.of(context)!
                              .unsupportedScrapeMessage)
                          : const CircularProgressIndicator(),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(state.recipe.name),
              ),
              body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints.expand(width: 1600),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            children: state.items.entries.map(
                              (entry) {
                                return StringItemMatch(
                                  household: widget.household,
                                  string: entry.key,
                                  item: entry.value,
                                  itemSelected: (item) {
                                    cubit.updateItem(entry.key, item);
                                  },
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: ElevatedButton(
                            onPressed: state.isValid()
                                ? () async {
                                    if (!cubit.hasValidRecipe()) return;
                                    final res = await Navigator.of(context)
                                        .push<UpdateEnum>(MaterialPageRoute(
                                      builder: (context) => AddUpdateRecipePage(
                                        household: widget.household,
                                        recipe: cubit.getRecipe()!,
                                        canSaveWithoutChanges: true,
                                      ),
                                    ));
                                    if (res == UpdateEnum.updated) {
                                      Navigator.of(context)
                                          .pop(UpdateEnum.updated);
                                    }
                                  }
                                : null,
                            child: Text(
                              AppLocalizations.of(context)!.next,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
