import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

enum _TagAction {
  rename,
  merge,
  delete;
}

class SliverHouseholdTagsSettings extends StatelessWidget {
  const SliverHouseholdTagsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.tags}:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: AppLocalizations.of(context)!.addTag,
              onPressed: () async {
                final res = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return TextDialog(
                      title: AppLocalizations.of(context)!.addTag,
                      doneText: AppLocalizations.of(context)!.add,
                      hintText: AppLocalizations.of(context)!.name,
                      isInputValid: (s) => s.isNotEmpty,
                    );
                  },
                );
                if (res != null) {
                  BlocProvider.of<HouseholdUpdateCubit>(context).addTag(res);
                }
              },
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
        buildWhen: (prev, curr) =>
            prev.tags != curr.tags || prev is LoadingHouseholdUpdateState,
        builder: (context, state) {
          if (state is LoadingHouseholdUpdateState) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: state.tags.length,
              (context, i) => DismissibleCard(
                key: ValueKey<Tag>(state.tags.elementAt(i)),
                confirmDismiss: (direction) async {
                  return (await askForConfirmation(
                    context: context,
                    title: Text(
                      AppLocalizations.of(context)!.tagDelete,
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.tagDeleteConfirmation(
                        state.tags.elementAt(i).name,
                      ),
                    ),
                  ));
                },
                onDismissed: (direction) {
                  BlocProvider.of<HouseholdUpdateCubit>(context)
                      .deleteTag(state.tags.elementAt(i));
                },
                title: Text(state.tags.elementAt(i).name),
                onTap: () async {
                  _handleAction(
                    context,
                    state.tags,
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
                                  state.tags.elementAt(i).name,
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
                                        .pop(_TagAction.rename),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.merge_rounded),
                                    label: Text(
                                      AppLocalizations.of(context)!.merge,
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .pop(_TagAction.merge),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.delete_rounded),
                                    label: Text(
                                      AppLocalizations.of(context)!.delete,
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .pop(_TagAction.delete),
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
          AppLocalizations.of(context)!.swipeToDelete,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }

//ignore: long-method
  Future<void> _handleAction(
    BuildContext context,
    Set<Tag> tags,
    int tagIndex,
    _TagAction? action,
  ) async {
    if (action == null) return;
    switch (action) {
      case _TagAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.tagEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: tags.elementAt(tagIndex).name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty && s != tags.elementAt(tagIndex).name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateTag(
            tags.elementAt(tagIndex).copyWith(name: res),
          );
        }
        break;
      case _TagAction.merge:
        Tag? other = await showDialog<Tag>(
          context: context,
          builder: (context) => SelectDialog(
            title: AppLocalizations.of(context)!.merge,
            cancelText: AppLocalizations.of(context)!.cancel,
            options: tags
                .whereIndexed((index, element) => index != tagIndex)
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
                tags.elementAt(tagIndex).name,
                other.name,
              ),
            ),
          );
          if (confirmed) {
            BlocProvider.of<HouseholdUpdateCubit>(context)
                .mergeTag(tags.elementAt(tagIndex), other);
          }
        }
        break;
      case _TagAction.delete:
        if (await askForConfirmation(
          context: context,
          title: Text(
            AppLocalizations.of(context)!.tagDelete,
          ),
          content: Text(
            AppLocalizations.of(context)!.tagDeleteConfirmation(
              tags.elementAt(tagIndex).name,
            ),
          ),
        )) {
          BlocProvider.of<HouseholdUpdateCubit>(context).deleteTag(
            tags.elementAt(tagIndex),
          );
        }
        break;
    }
  }
}
