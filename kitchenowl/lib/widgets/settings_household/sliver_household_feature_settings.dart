import 'package:flutter/foundation.dart';
import 'package:kitchenowl/helpers/localized_language.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_add_update_cubit.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/language_bottom_sheet.dart';
import 'package:reorderables/reorderables.dart';
import 'package:world_countries/world_countries.dart';

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
                return Text(
                  LocalizedLanguage.nameOf(
                        context,
                        state.language,
                        state.supportedLanguages,
                      ) ??
                      state.language!,
                );
              }

              return LoadingElevatedButton(
                child: Text(
                  LocalizedLanguage.nameOf(
                        context,
                        state.language,
                        state.supportedLanguages,
                      ) ??
                      state.language ??
                      AppLocalizations.of(context)!.set,
                ),
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
                            .addLanguageConfirm(language.value ?? ""),
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
        BlocBuilder<Cubit, State>(
          buildWhen: (previous, current) =>
              previous.featureExpenses != current.featureExpenses ||
              previous.currency != current.currency ||
              previous.language != current.language,
          builder: (context, state) {
            if (!state.featureExpenses) return const SizedBox();
            final selectedCurrency =
                LocalizedLanguage.currencyOf(state.currency ?? state.language);

            return ListTile(
              title: Text(AppLocalizations.of(context)!.currency),
              leading: const Icon(Icons.currency_exchange_rounded),
              contentPadding: const EdgeInsets.only(left: 16, right: 21),
              trailing: LoadingElevatedButton(
                child: Text(
                  LocalizedLanguage.currencyNameOf(context, selectedCurrency) ??
                      AppLocalizations.of(context)!.set,
                ),
                onPressed: () async {
                  final currency = await CurrencyPicker(
                    currencies: LocalizedLanguage.supportedCurrencies(context),
                    chosen: [if (selectedCurrency != null) selectedCurrency],
                    searchBar: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        labelText: AppLocalizations.of(context)!.searchHint,
                      ),
                    ),
                    itemBuilder: (props, tile) => tile?.copyWith(
                      chosenIcon: const Icon(Icons.check_circle_rounded),
                    ),
                  ).showInModalBottomSheet(
                    context,
                    showDragHandle: true,
                    shape: null,
                  );
                  if (currency == null || !context.mounted) return;
                  final locale = LocalizedLanguage.localeForCurrency(currency);
                  if (locale == null) return;
                  await BlocProvider.of<Cubit>(context).setCurrency(locale);
                },
              ),
            );
          },
        ),
      ]),
    );
  }
}
