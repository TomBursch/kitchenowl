import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/planner_cubit.dart';
import 'package:kitchenowl/cubits/recipe_list_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/home_page/home_page_item_wrapper.dart';

import 'home_page_item.dart';

class OverflowPage extends StatelessWidget with HomePageItem {
  final List<HomePageItem> pages;

  const OverflowPage({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: true,
      slivers: [
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: pages
                    .map(
                      (view) => Card(
                        child: ListTile(
                          title: Text(view.label(context)),
                          leading: Icon(view.icon(context)),
                          minLeadingWidth: 16,
                          onTap: () {
                            view.onSelected(context, false);
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                    value: BlocProvider.of<ShoppinglistCubit>(
                                      context,
                                    ),
                                  ),
                                  BlocProvider.value(
                                    value: BlocProvider.of<RecipeListCubit>(
                                      context,
                                    ),
                                  ),
                                  BlocProvider.value(
                                    value:
                                        BlocProvider.of<PlannerCubit>(context),
                                  ),
                                  BlocProvider.value(
                                    value: BlocProvider.of<ExpenseListCubit>(
                                      context,
                                    ),
                                  ),
                                ],
                                child: HomePageItemWrapper(
                                  homePageItem: view,
                                ),
                              ),
                            ));
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  IconData icon(context) =>
      App.isOffline ? Icons.cloud_off_rounded : Icons.view_headline_rounded;

  @override
  ViewsEnum type() => ViewsEnum.profile;

  @override
  String label(context) => AppLocalizations.of(context)!.more;
}
