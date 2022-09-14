import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
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
          delegate: ReorderableSliverChildBuilderDelegate(
            childCount: state.categories.length,
            (context, i) => Dismissible(
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
                    state.categories.elementAt(i).name,
                  ),
                  onTap: () async {
                    final res = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        return TextDialog(
                          title: AppLocalizations.of(context)!.addTag,
                          doneText: AppLocalizations.of(context)!.rename,
                          hintText: AppLocalizations.of(context)!.name,
                          initialText: state.categories.elementAt(i).name,
                        );
                      },
                    );
                    if (res != null && res.isNotEmpty) {
                      BlocProvider.of<SettingsServerCubit>(context)
                          .updateCategory(state.categories
                              .elementAt(i)
                              .copyWith(name: res));
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
