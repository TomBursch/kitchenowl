import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:reorderables/reorderables.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverHouseholdCategorySettings extends StatelessWidget {
  const SliverHouseholdCategorySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiSliver(children: [
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.categories}:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppLocalizations.of(context)!.addCategory,
              onPressed: () async {
                final res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return TextDialog(
                      title: AppLocalizations.of(context)!.addCategory,
                      doneText: AppLocalizations.of(context)!.add,
                      hintText: AppLocalizations.of(context)!.name,
                      isInputValid: (s) => s.isNotEmpty,
                    );
                  },
                );
                if (res != null) {
                  BlocProvider.of<HouseholdUpdateCubit>(context)
                      .addCategory(res);
                }
              },
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
        buildWhen: (prev, curr) =>
            prev.categories != curr.categories ||
            prev is LoadingHouseholdUpdateState,
        builder: (context, state) {
          if (state is LoadingHouseholdUpdateState) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return ReorderableSliverList(
            onReorder:
                BlocProvider.of<HouseholdUpdateCubit>(context).reorderCategory,
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
                  BlocProvider.of<HouseholdUpdateCubit>(context).deleteCategory(
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
                    BlocProvider.of<HouseholdUpdateCubit>(context)
                        .updateCategory(
                      state.categories.elementAt(i).copyWith(name: res),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
      SliverToBoxAdapter(
        child: Text(
          AppLocalizations.of(context)!.swipeToDeleteAndLongPressToReorder,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }
}
