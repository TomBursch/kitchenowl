import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_household_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/pages/expense_category_add_update_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverHouseholdExpenseCategorySettings extends StatelessWidget {
  const SliverHouseholdExpenseCategorySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsHouseholdCubit, SettingsHouseholdState>(
      buildWhen: (prev, curr) =>
          prev.featureExpenses != curr.featureExpenses ||
          prev.expenseCategories != curr.expenseCategories ||
          prev is LoadingSettingsHouseholdState,
      builder: (context, state) {
        if (!state.featureExpenses) {
          return const SliverToBoxAdapter(
            child: SizedBox(),
          );
        }

        if (state is LoadingSettingsHouseholdState) {
          return SliverList(
            delegate: SliverChildListDelegate([
              Text(
                '${AppLocalizations.of(context)!.expenseCategories}:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ]),
          );
        }

        return MultiSliver(children: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.expenseCategories}:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final res = await Navigator.of(context).push<UpdateEnum>(
                      MaterialPageRoute(
                        builder: (context) => AddUpdateExpenseCategoryPage(
                          household:
                              BlocProvider.of<SettingsHouseholdCubit>(context)
                                  .household,
                        ),
                      ),
                    );
                    if (res == UpdateEnum.updated ||
                        res == UpdateEnum.updated) {
                      BlocProvider.of<SettingsHouseholdCubit>(
                        context,
                      ).refresh();
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: state.expenseCategories.length,
              (context, i) => DismissibleCard(
                key: ValueKey<ExpenseCategory>(
                  state.expenseCategories.elementAt(i),
                ),
                confirmDismiss: (direction) async {
                  return (await askForConfirmation(
                    context: context,
                    title: Text(
                      AppLocalizations.of(context)!.categoryDelete,
                    ),
                    content: Text(
                      AppLocalizations.of(context)!
                          .categoryExpenseDeleteConfirmation(
                        state.expenseCategories.elementAt(i).name,
                      ),
                    ),
                  ));
                },
                onDismissed: (direction) {
                  BlocProvider.of<SettingsHouseholdCubit>(context)
                      .deleteExpenseCategory(
                    state.expenseCategories.elementAt(i),
                  );
                },
                title: Text(
                  state.expenseCategories.elementAt(i).name,
                ),
                onTap: () async {
                  final res = await Navigator.of(context)
                      .push<UpdateEnum>(MaterialPageRoute(
                    builder: (context) => AddUpdateExpenseCategoryPage(
                      household:
                          BlocProvider.of<SettingsHouseholdCubit>(context)
                              .household,
                      category: state.expenseCategories.elementAt(i),
                    ),
                  ));
                  if (res == UpdateEnum.updated || res == UpdateEnum.updated) {
                    BlocProvider.of<SettingsHouseholdCubit>(context).refresh();
                  }
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Text(
              AppLocalizations.of(context)!.swipeToDelete,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ]);
      },
    );
  }
}
