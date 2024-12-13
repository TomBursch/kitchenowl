import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

enum _ShoppinglistAction {
  rename,
  delete;
}

class HouseholdSettingsShoppinglistPage extends StatelessWidget {
  const HouseholdSettingsShoppinglistPage({super.key});

  static Future<bool> confirmDeleteShoppingList(
      BuildContext context, ShoppingList shoppinglist) async {
    return await askForConfirmation(
        context: context,
        title: Text(
          AppLocalizations.of(context)!.shoppingListDelete,
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                AppLocalizations.of(context)!.shoppingListDeleteConfirmation(
                  shoppinglist.name,
                ),
              ),
              if (shoppinglist.items.length > 0) const SizedBox(height: 20),
              if (shoppinglist.items.length > 0)
                Text(AppLocalizations.of(context)!
                    .shoppingListContainsEntries(shoppinglist.items.length))
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context)!.shoppingLists),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.addShoppingList,
                onPressed: () async {
                  final res = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return TextDialog(
                        title: AppLocalizations.of(context)!.addShoppingList,
                        doneText: AppLocalizations.of(context)!.add,
                        hintText: AppLocalizations.of(context)!.name,
                        isInputValid: (s) => s.isNotEmpty,
                      );
                    },
                  );
                  if (res != null) {
                    BlocProvider.of<HouseholdUpdateCubit>(context)
                        .addShoppingList(res);
                  }
                },
              ),
            ],
          ),
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 600,
            child: BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
              buildWhen: (prev, curr) =>
                  prev.shoppingLists != curr.shoppingLists ||
                  prev is LoadingHouseholdUpdateState,
              builder: (context, state) {
                if (state is LoadingHouseholdUpdateState) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: state.shoppingLists.length,
                    (context, i) => DismissibleCard(
                      key: ValueKey<String>(
                        state.shoppingLists.elementAt(i).name,
                      ),
                      isDismissable: i != 0,
                      confirmDismiss: (direction) async =>
                          await confirmDeleteShoppingList(
                              context, state.shoppingLists.elementAt(i)),
                      onDismissed: (direction) {
                        BlocProvider.of<HouseholdUpdateCubit>(context)
                            .deleteShoppingList(
                          state.shoppingLists.elementAt(i),
                        );
                      },
                      title: Text(
                        state.shoppingLists.elementAt(i).name,
                      ),
                      subtitle: i == 0
                          ? Text(
                              '(${AppLocalizations.of(context)!.defaultWord})',
                            )
                          : null,
                      onTap: () async {
                        _handleAction(
                          context,
                          state.shoppingLists,
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
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        state.shoppingLists.elementAt(i).name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
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
                                              .pop(_ShoppinglistAction.rename),
                                        ),
                                        if (i != 0)
                                          ActionChip(
                                            avatar: const Icon(
                                                Icons.delete_rounded),
                                            label: Text(
                                              AppLocalizations.of(context)!
                                                  .delete,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop(
                                                    _ShoppinglistAction.delete),
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
    List<ShoppingList> shoppingLists,
    int shoppingListIndex,
    _ShoppinglistAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case _ShoppinglistAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.shoppingListEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: shoppingLists.elementAt(shoppingListIndex).name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty &&
                  s != shoppingLists.elementAt(shoppingListIndex).name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateShoppingList(
            shoppingLists.elementAt(shoppingListIndex).copyWith(name: res),
          );
        }
        break;
      case _ShoppinglistAction.delete:
        if (await confirmDeleteShoppingList(
            context, shoppingLists.elementAt(shoppingListIndex))) {
          BlocProvider.of<HouseholdUpdateCubit>(context).deleteShoppingList(
            shoppingLists.elementAt(shoppingListIndex),
          );
        }
        break;
    }
  }
}
