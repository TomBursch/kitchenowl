import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:reorderables/reorderables.dart';

enum _CategoryAction {
  rename,
  merge,
  delete;
}

class SliverHouseholdCategorySettings extends StatelessWidget {
  const SliverHouseholdCategorySettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: [
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
                      isInputValid: (s) => s.trim().isNotEmpty,
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
                  _handleAction(
                    context,
                    state.categories,
                    i,
                    await showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  state.categories.elementAt(i).name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const Divider(),
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.edit_rounded),
                                    label: Text(
                                      AppLocalizations.of(context)!.rename,
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .pop(_CategoryAction.rename),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.merge_rounded),
                                    label: Text(
                                      AppLocalizations.of(context)!.merge,
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .pop(_CategoryAction.merge),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.delete_rounded),
                                    label: Text(
                                      AppLocalizations.of(context)!.delete,
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .pop(_CategoryAction.delete),
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
      SliverToBoxAdapter(
        child: Text(
          AppLocalizations.of(context)!.swipeToDeleteAndLongPressToReorder,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }

  //ignore: long-method
  Future<void> _handleAction(
    BuildContext context,
    List<Category> categories,
    int categoryIndex,
    _CategoryAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case _CategoryAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.categoryEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: categories.elementAt(categoryIndex).name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty &&
                  s != categories.elementAt(categoryIndex).name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateCategory(
            categories.elementAt(categoryIndex).copyWith(name: res),
          );
        }
        break;
      case _CategoryAction.merge:
        Category? other = await showDialog<Category>(
          context: context,
          builder: (context) => SelectDialog(
            title: AppLocalizations.of(context)!.merge,
            cancelText: AppLocalizations.of(context)!.cancel,
            options: categories
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
                categories.elementAt(categoryIndex).name,
                other.name,
              ),
            ),
          );
          if (confirmed) {
            BlocProvider.of<HouseholdUpdateCubit>(context)
                .mergeCategory(categories.elementAt(categoryIndex), other);
          }
        }
        break;
      case _CategoryAction.delete:
        if (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.categoryDelete,
          ),
          content: Text(
            AppLocalizations.of(context)!.categoryDeleteConfirmation(
              categories.elementAt(categoryIndex).name,
            ),
          ),
        )) {
          BlocProvider.of<HouseholdUpdateCubit>(context).deleteCategory(
            categories.elementAt(categoryIndex),
          );
        }
        break;
    }
  }
}
