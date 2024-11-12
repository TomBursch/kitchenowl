import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:kitchenowl/cubits/household_add_update/household_add_update_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/language_bottom_sheet.dart';
import 'package:reorderables/reorderables.dart';

import 'view_settings_list_tile.dart';

class SliverHouseholdFeatureSettings<
    Cubit extends HouseholdAddUpdateCubit<State>,
    State extends HouseholdAddUpdateState> extends StatelessWidget {
  final bool languageCanBeChanged;
  final bool askConfirmation;

  const SliverHouseholdFeatureSettings({
    super.key,
    this.languageCanBeChanged = false,
    this.askConfirmation = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: BlocBuilder<Cubit, State>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.features}:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 40),
                if (!listEquals(state.viewOrdering, ViewsEnum.values))
                  IconButton(
                    onPressed: BlocProvider.of<Cubit>(context).resetViewOrder,
                    tooltip: AppLocalizations.of(context)!.reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
        BlocBuilder<Cubit, State>(
          builder: (context, state) => ReorderableColumn(
            onReorder: BlocProvider.of<Cubit>(context).reorderView,
            children: state.viewOrdering
                .sublist(0, state.viewOrdering.length - 1)
                .map(
                  (view) => ViewSettingsListTile<Cubit>(
                    key: ValueKey(view),
                    view: view,
                    isActive: state.isViewActive(view),
                  ),
                )
                .toList(),
          ),
        ),
        Center(child: Text(AppLocalizations.of(context)!.longPressToReorder)),
        const SizedBox(height: 8),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          title: Text(AppLocalizations.of(context)!.language),
          leading: const Icon(Icons.language_rounded),
          contentPadding: const EdgeInsets.only(left: 16, right: 21),
          trailing: BlocBuilder<Cubit, State>(
            buildWhen: (previous, current) =>
                previous.language != current.language ||
                previous.supportedLanguages != current.supportedLanguages,
            builder: (context, state) {
              if (state.language != null && !languageCanBeChanged) {
                return Text(LocaleNames.of(context)!.nameOf(state.language!) ??
                    state.supportedLanguages?[state.language!] ??
                    state.language!);
              }

              return LoadingElevatedButton(
                child: Text(
                    LocaleNames.of(context)!.nameOf(state.language ?? "") ??
                        state.supportedLanguages?[state.language] ??
                        state.language ??
                        AppLocalizations.of(context)!.set),
                onPressed: () async {
                  final language = await showModalBottomSheet<Nullable<String>>(
                    context: context,
                    showDragHandle: true,
                    builder: (BuildContext context) {
                      return LanguageBottomSheet(
                        title: AppLocalizations.of(context)!.language,
                        doneText: AppLocalizations.of(context)!.set,
                        initialLanguage: state.language,
                        supportedLanguages: state.supportedLanguages,
                      );
                    },
                  );
                  if (language == null) return;
                  if (askConfirmation) {
                    final confirm = await askForConfirmation(
                      context: context,
                      confirmText: AppLocalizations.of(context)!.set,
                      title: Text(
                        AppLocalizations.of(context)!.addLanguage,
                      ),
                      content: Text(
                        AppLocalizations.of(context)!
                            .addLanguageConfirm(language),
                      ),
                    );
                    if (!confirm) return;
                  }
                  BlocProvider.of<Cubit>(context).setLanguage(language.value);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
