import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
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
                key: ValueKey<String>(
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
                  state.expenseCategories.elementAt(i),
                ),
                onTap: () async {
                  final res = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return TextDialog(
                        title: AppLocalizations.of(context)!.addTag,
                        doneText: AppLocalizations.of(context)!.rename,
                        hintText: AppLocalizations.of(context)!.name,
                        initialText: state.expenseCategories.elementAt(i),
                        isInputValid: (s) =>
                            s.isNotEmpty &&
                            s != state.expenseCategories.elementAt(i),
                      );
                    },
                  );
                  if (res != null) {
                    BlocProvider.of<SettingsServerCubit>(context)
                        .renameExpenseCategory(
                      state.expenseCategories.elementAt(i),
                      res,
                    );
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
