import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_add_update_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/language_dialog.dart';
import 'package:reorderables/reorderables.dart';

import 'view_settings_list_tile.dart';

class SliverHouseholdFeatureSettings<
    Cubit extends HouseholdAddUpdateCubit<State>,
    State extends HouseholdAddUpdateState> extends StatelessWidget {
  final bool languageCanBeChanged;
  final bool askConfirmation;
  final bool showProfile;

  const SliverHouseholdFeatureSettings({
    super.key,
    this.languageCanBeChanged = false,
    this.askConfirmation = true,
    this.showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        BlocBuilder<Cubit, State>(
          builder: (context, state) => Row(
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context)!.features}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
        const SizedBox(height: 8),
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
        if (showProfile)
          const ViewSettingsListTile(
            view: ViewsEnum.profile,
            showHandleIfNotOptional: false,
          ),
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.language),
          leading: const Icon(Icons.language_rounded),
          contentPadding: const EdgeInsets.only(left: 20, right: 5),
          trailing: BlocBuilder<Cubit, State>(
            buildWhen: (previous, current) =>
                previous.language != current.language ||
                previous.supportedLanguages != current.supportedLanguages,
            builder: (context, state) {
              if (state.language != null && !languageCanBeChanged) {
                return Text(state.supportedLanguages?[state.language!] ??
                    state.language!);
              }

              return LoadingElevatedButton(
                child: Text(state.supportedLanguages?[state.language] ??
                    state.language ??
                    AppLocalizations.of(context)!.set),
                onPressed: () async {
                  final language = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return LanguageDialog(
                        title: AppLocalizations.of(context)!.language,
                        doneText: AppLocalizations.of(context)!.set,
                        initialLanguage: state.language ??
                            AppLocalizations.of(context)!.localeName,
                        supportedLanguages: state.supportedLanguages,
                      );
                    },
                  );
                  if (language == null) {
                    BlocProvider.of<Cubit>(context).setLanguage(language);
                  } else {
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
                    BlocProvider.of<Cubit>(context).setLanguage(language);
                  }
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
