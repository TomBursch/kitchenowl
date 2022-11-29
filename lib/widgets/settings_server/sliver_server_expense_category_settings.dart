import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/pages/expense_category_add_update_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

class SliverServerExpenseCategorySettings extends StatelessWidget {
  const SliverServerExpenseCategorySettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.serverSettings.featureExpenses !=
          curr.serverSettings.featureExpenses,
      builder: (context, settingsState) =>
          BlocBuilder<SettingsServerCubit, SettingsServerState>(
        buildWhen: (prev, curr) =>
            prev.expenseCategories != curr.expenseCategories ||
            prev is LoadingSettingsServerState,
        builder: (context, state) {
          if (state is LoadingSettingsServerState) {
            return const SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return SliverList(
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
                        state.expenseCategories.elementAt(i),
                      ),
                    ),
                  ));
                },
                onDismissed: (direction) {
                  BlocProvider.of<SettingsServerCubit>(context)
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
                      category: state.expenseCategories.elementAt(i),
                    ),
                  ));
                  if (res == UpdateEnum.updated || res == UpdateEnum.updated) {
                    BlocProvider.of<SettingsServerCubit>(context).refresh();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
