import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

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
              (context, i) => Dismissible(
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
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.redAccent,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.redAccent,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  child: ListTile(
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
                          );
                        },
                      );
                      if (res != null && res.isNotEmpty) {
                        BlocProvider.of<SettingsServerCubit>(context)
                            .renameExpenseCategory(res);
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
