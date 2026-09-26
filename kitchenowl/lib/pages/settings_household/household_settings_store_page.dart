import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/store.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

enum _StoreAction {
  rename,
  merge,
  delete;
}

class HouseholdSettingsStorePage extends StatelessWidget {
  const HouseholdSettingsStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context)!.stores),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.addStore,
                onPressed: () async {
                  final res = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return TextDialog(
                        title: AppLocalizations.of(context)!.addStore,
                        doneText: AppLocalizations.of(context)!.add,
                        hintText: AppLocalizations.of(context)!.name,
                        isInputValid: (s) => s.isNotEmpty,
                      );
                    },
                  );
                  if (res != null) {
                    BlocProvider.of<HouseholdUpdateCubit>(context)
                        .addStore(res);
                  }
                },
              ),
            ],
          ),
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 600,
            child: BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
              buildWhen: (prev, curr) =>
                  prev.stores != curr.stores ||
                  prev is LoadingHouseholdUpdateState,
              builder: (context, state) {
                if (state is LoadingHouseholdUpdateState) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: state.stores.length,
                    (context, i) => DismissibleCard(
                      key: ValueKey<Store>(state.stores.elementAt(i)),
                      confirmDismiss: (direction) async {
                        return (await askForConfirmation(
                          context: context,
                          title: Text(
                            AppLocalizations.of(context)!.storeDelete,
                          ),
                          content: Text(
                            AppLocalizations.of(context)!
                                .storeDeleteConfirmation(
                              state.stores.elementAt(i).name,
                            ),
                          ),
                        ));
                      },
                      onDismissed: (direction) {
                        BlocProvider.of<HouseholdUpdateCubit>(context)
                            .deleteStore(state.stores.elementAt(i));
                      },
                      title: Text(state.stores.elementAt(i).name),
                      onTap: () async {
                        _handleAction(
                          context,
                          state.stores,
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
                                        state.stores.elementAt(i).name,
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
                                              .pop(_StoreAction.rename),
                                        ),
                                        ActionChip(
                                          avatar:
                                              const Icon(Icons.merge_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!.merge,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_StoreAction.merge),
                                        ),
                                        ActionChip(
                                          avatar:
                                              const Icon(Icons.delete_rounded),
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .delete,
                                          ),
                                          onPressed: () => Navigator.of(context)
                                              .pop(_StoreAction.delete),
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
    Set<Store> stores,
    int storeIndex,
    _StoreAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case _StoreAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.storeEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: stores.elementAt(storeIndex).name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty && s != stores.elementAt(storeIndex).name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateStore(
            stores.elementAt(storeIndex).copyWith(name: res),
          );
        }
        break;
      case _StoreAction.merge:
        Store? other = await showDialog<Store>(
          context: context,
          builder: (context) => SelectDialog(
            title: AppLocalizations.of(context)!.merge,
            cancelText: AppLocalizations.of(context)!.cancel,
            options: stores
                .whereIndexed((index, element) => index != storeIndex)
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
              AppLocalizations.of(context)!.merge,
            ),
            confirmText: AppLocalizations.of(context)!.merge,
            content: Text(
              AppLocalizations.of(context)!.itemsMergeConfirmation(
                stores.elementAt(storeIndex).name,
                other.name,
              ),
            ),
          );
          if (confirmed) {
            BlocProvider.of<HouseholdUpdateCubit>(context)
                .mergeStore(stores.elementAt(storeIndex), other);
          }
        }
        break;
      case _StoreAction.delete:
        if (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.storeDelete,
          ),
          content: Text(
            AppLocalizations.of(context)!.storeDeleteConfirmation(
              stores.elementAt(storeIndex).name,
            ),
          ),
        )) {
          BlocProvider.of<HouseholdUpdateCubit>(context).deleteStore(
            stores.elementAt(storeIndex),
          );
        }
        break;
    }
  }
}
