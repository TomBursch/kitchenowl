import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:reorderables/reorderables.dart';

class SliverServerCategorySettings extends StatelessWidget {
  const SliverServerCategorySettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsServerCubit, SettingsServerState>(
      buildWhen: (prev, curr) =>
          prev.categories != curr.categories ||
          prev is LoadingSettingsServerState,
      builder: (context, state) {
        if (state is LoadingSettingsServerState) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ReorderableSliverList(
          onReorder:
              BlocProvider.of<SettingsServerCubit>(context).reorderCategory,
          buildDraggableFeedback: (_, c, w) => ConstrainedBox(
            constraints: c,
            child: w,
          ),
          delegate: ReorderableSliverChildBuilderDelegate(
            childCount: state.categories.length,
            (context, i) => DismissibleCard(
              key: ValueKey<String>(
                state.categories.elementAt(i).name,
              ),
              confirmDismiss: (direction) async {
                return (await askForConfirmation(
                  context: context,
                  title: Text(
                    AppLocalizations.of(context)!.categoryDelete,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.categoryDeleteConfirmation(
                      state.categories.elementAt(i).name,
                    ),
                  ),
                ));
              },
              onDismissed: (direction) {
                BlocProvider.of<SettingsServerCubit>(context).deleteCategory(
                  state.categories.elementAt(i),
                );
              },
              title: Text(
                state.categories.elementAt(i).name,
              ),
              displayDraggable: true,
              onTap: () async {
                final res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return TextDialog(
                      title: AppLocalizations.of(context)!.categoryEdit,
                      doneText: AppLocalizations.of(context)!.rename,
                      hintText: AppLocalizations.of(context)!.name,
                      initialText: state.categories.elementAt(i).name,
                      isInputValid: (s) =>
                          s.isNotEmpty &&
                          s != state.categories.elementAt(i).name,
                    );
                  },
                );
                if (res != null) {
                  BlocProvider.of<SettingsServerCubit>(context).updateCategory(
                    state.categories.elementAt(i).copyWith(name: res),
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
