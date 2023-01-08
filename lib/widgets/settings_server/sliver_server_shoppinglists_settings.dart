import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

class SliverServerShoppingListsSettings extends StatelessWidget {
  const SliverServerShoppingListsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsServerCubit, SettingsServerState>(
      buildWhen: (prev, curr) =>
          prev.shoppingLists != curr.shoppingLists ||
          prev is LoadingSettingsServerState,
      builder: (context, state) {
        if (state is LoadingSettingsServerState) {
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
              isDismissable: state.shoppingLists.elementAt(i).id != 1,
              confirmDismiss: (direction) async {
                return (await askForConfirmation(
                  context: context,
                  title: Text(
                    AppLocalizations.of(context)!.shoppingListDelete,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!
                        .shoppingListDeleteConfirmation(
                      state.shoppingLists.elementAt(i).name,
                    ),
                  ),
                ));
              },
              onDismissed: (direction) {
                BlocProvider.of<SettingsServerCubit>(context)
                    .deleteShoppingList(
                  state.shoppingLists.elementAt(i),
                );
              },
              title: Text(
                state.shoppingLists.elementAt(i).name,
              ),
              subtitle: ((state.shoppingLists.elementAt(i).id ?? 0) == 1)
                  ? Text('(${AppLocalizations.of(context)!.defaultWord})')
                  : null,
              onTap: () async {
                final res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return TextDialog(
                      title: AppLocalizations.of(context)!.shoppingListEdit,
                      doneText: AppLocalizations.of(context)!.rename,
                      hintText: AppLocalizations.of(context)!.name,
                      initialText: state.shoppingLists.elementAt(i).name,
                      isInputValid: (s) =>
                          s.isNotEmpty &&
                          s != state.shoppingLists.elementAt(i).name,
                    );
                  },
                );
                if (res != null) {
                  BlocProvider.of<SettingsServerCubit>(context)
                      .updateShoppingList(
                    state.shoppingLists.elementAt(i).copyWith(name: res),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
