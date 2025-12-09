import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/pages/expense_category_add_page.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:kitchenowl/widgets/expense_category_icon.dart';
import 'package:kitchenowl/widgets/kitchenowl_color_picker_dialog.dart';
import 'package:sliver_tools/sliver_tools.dart';

enum _ExpenseCategoryAction {
  rename,
  setColor,
  setBudget,
  merge,
  delete;
}

class HouseholdSettingsExpenseCategoryPage extends StatelessWidget {
  const HouseholdSettingsExpenseCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context)!.expenseCategories),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.addCategory,
                onPressed: () async {
                  final res = await Navigator.of(context).push<UpdateEnum>(
                    MaterialPageRoute(
                      builder: (ctx) => AddExpenseCategoryPage(
                        household:
                            BlocProvider.of<HouseholdUpdateCubit>(context)
                                .household,
                      ),
                    ),
                  );
                  if (res == UpdateEnum.updated) {
                    BlocProvider.of<HouseholdUpdateCubit>(
                      context,
                    ).refresh();
                  }
                },
              ),
            ],
          ),
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 600,
            child: BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
              buildWhen: (prev, curr) =>
                  prev.expenseCategories != curr.expenseCategories ||
                  prev is LoadingHouseholdUpdateState,
              builder: (context, state) {
                if (state is LoadingHouseholdUpdateState) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
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
                              state.expenseCategories.elementAt(i).name,
                            ),
                          ),
                        ));
                      },
                      onDismissed: (direction) {
                        BlocProvider.of<HouseholdUpdateCubit>(context)
                            .deleteExpenseCategory(
                          state.expenseCategories.elementAt(i),
                        );
                      },
                      title: Text(
                        state.expenseCategories.elementAt(i).name,
                      ),
                      subtitle: state.expenseCategories[i].budget != null
                          ? Text(
                              "${AppLocalizations.of(context)!.budget}: ${NumberFormat.simpleCurrency(locale: state.language).format(state.expenseCategories.elementAt(i).budget)}")
                          : null,
                      onTap: () async {
                        _handleAction(
                          context,
                          state.expenseCategories,
                          i,
                          await showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            builder: (context) => SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: SizedBox(
                                            height: 50,
                                            child: ExpenseCategoryIcon(
                                              name: state.expenseCategories
                                                  .elementAt(i)
                                                  .name,
                                              color: state.expenseCategories
                                                  .elementAt(i)
                                                  .color,
                                              textScaleFactor: 1,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                            state.expenseCategories
                                                .elementAt(i)
                                                .name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ActionChip(
                                          avatar:
                                              const Icon(Icons.edit_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .rename,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_ExpenseCategoryAction
                                                  .rename),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(
                                              Icons.color_lens_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .colorSelect,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_ExpenseCategoryAction
                                                  .setColor),
                                        ),
                                        ActionChip(
                                          avatar: const Icon(
                                              Icons.attach_money_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .budgetSet,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_ExpenseCategoryAction
                                                  .setBudget),
                                        ),
                                        ActionChip(
                                          avatar:
                                              const Icon(Icons.merge_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!.merge,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(
                                                  _ExpenseCategoryAction.merge),
                                        ),
                                        ActionChip(
                                          avatar:
                                              const Icon(Icons.delete_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .delete,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_ExpenseCategoryAction
                                                  .delete),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //ignore: long-method
  Future<void> _handleAction(
    BuildContext context,
    List<ExpenseCategory> expenseCategories,
    int categoryIndex,
    _ExpenseCategoryAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case _ExpenseCategoryAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.categoryEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: expenseCategories.elementAt(categoryIndex).name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty &&
                  s != expenseCategories.elementAt(categoryIndex).name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateExpenseCategory(
            expenseCategories.elementAt(categoryIndex).copyWith(name: res),
          );
        }
        break;
      case _ExpenseCategoryAction.setColor:
        final color = await showDialog<Nullable<Color>>(
          context: context,
          builder: (context) => KitchenOwlColorPickerDialog(
            initialColor: expenseCategories.elementAt(categoryIndex).color,
          ),
        );
        if (color != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateExpenseCategory(
            expenseCategories.elementAt(categoryIndex).copyWith(color: color),
          );
        }
        break;
      case _ExpenseCategoryAction.setBudget:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.budgetSet,
              doneText: AppLocalizations.of(context)!.set,
              textInputType: TextInputType.numberWithOptions(decimal: true),
              hintText: AppLocalizations.of(context)!.budget,
              initialText:
                  expenseCategories.elementAt(categoryIndex).budget?.toString(),
              isInputValid: (s) =>
                  s.trim().isNotEmpty &&
                  s != expenseCategories.elementAt(categoryIndex).budget &&
                  double.tryParse(s) != null,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop("clear"),
                  child: Text(AppLocalizations.of(context)!.clear),
                )
              ],
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateExpenseCategory(
            expenseCategories.elementAt(categoryIndex).copyWith(
                  budget: res == "clear"
                      ? Nullable.empty()
                      : Nullable(double.tryParse(res)),
                ),
          );
        }
        break;
      case _ExpenseCategoryAction.merge:
        ExpenseCategory? other = await showDialog<ExpenseCategory>(
          context: context,
          builder: (context) => SelectDialog(
            title: AppLocalizations.of(context)!.merge,
            cancelText: AppLocalizations.of(context)!.cancel,
            options: expenseCategories
                .whereIndexed((index, element) => index != categoryIndex)
                .map(
                  (e) => SelectDialogOption(
                    e,
                    e.name,
                  ),
                )
                .toList(),
          ),
        );
        if (other != null) {
          final confirmed = await askForConfirmation(
            context: context,
            title: Text(
              AppLocalizations.of(context)!.categoriesMerge,
            ),
            confirmText: AppLocalizations.of(context)!.merge,
            content: Text(
              AppLocalizations.of(context)!.itemsMergeConfirmation(
                expenseCategories.elementAt(categoryIndex).name,
                other.name,
              ),
            ),
          );
          if (confirmed) {
            BlocProvider.of<HouseholdUpdateCubit>(context).mergeExpenseCategory(
              expenseCategories.elementAt(categoryIndex),
              other,
            );
          }
        }
        break;
      case _ExpenseCategoryAction.delete:
        if (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.categoryDelete,
          ),
          content: Text(
            AppLocalizations.of(context)!.categoryExpenseDeleteConfirmation(
              expenseCategories.elementAt(categoryIndex).name,
            ),
          ),
        )) {
          BlocProvider.of<HouseholdUpdateCubit>(context).deleteExpenseCategory(
            expenseCategories.elementAt(categoryIndex),
          );
        }
        break;
    }
  }
}
