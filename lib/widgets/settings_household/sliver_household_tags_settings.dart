import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';

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
                  final res = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return TextDialog(
                        title: AppLocalizations.of(context)!.tagEdit,
                        doneText: AppLocalizations.of(context)!.rename,
                        hintText: AppLocalizations.of(context)!.name,
                        initialText: state.tags.elementAt(i).name,
                        isInputValid: (s) =>
                            s.isNotEmpty && s != state.tags.elementAt(i).name,
                      );
                    },
                  );
                  if (res != null) {
                    BlocProvider.of<HouseholdUpdateCubit>(context).updateTag(
                      state.tags.elementAt(i).copyWith(name: res),
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
          AppLocalizations.of(context)!.swipeToDelete,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }
}
