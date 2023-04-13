import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/enums/token_type_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/token.dart';

class SettingsUserSessionsPage extends StatelessWidget {
  final SettingsUserCubit cubit;

  const SettingsUserSessionsPage({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sessions),
      ),
      body: BlocBuilder<SettingsUserCubit, SettingsUserState>(
        bloc: cubit,
        buildWhen: (prev, curr) => prev.user?.tokens != curr.user?.tokens,
        builder: (context, state) => CustomScrollView(slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Card(
                child: ListTile(
                  title: Text(
                    state.user!.tokens!
                        .where((e) => e.type == TokenTypeEnum.refresh)
                        .elementAt(i)
                        .name,
                  ),
                ),
              ),
              childCount: state.user?.tokens
                      ?.where((e) => e.type == TokenTypeEnum.refresh)
                      .length ??
                  0,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              if (state.user!.tokens!
                  .where(
                    (e) => e.type == TokenTypeEnum.refresh,
                  )
                  .isNotEmpty) ...[
                Text(
                  '${AppLocalizations.of(context)!.sessions}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
              ],
              TextWithIconButton(
                title: '${AppLocalizations.of(context)!.llts}:',
                icon: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.lltCreate,
                onPressed: () => _createLLTflow(context),
              ),
              const SizedBox(height: 8),
            ]),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: state.user?.tokens
                      ?.where(
                        (e) => e.type == TokenTypeEnum.longlived,
                      )
                      .length ??
                  0,
              (context, i) {
                final token = state.user!.tokens!
                    .where(
                      (e) => e.type == TokenTypeEnum.longlived,
                    )
                    .elementAt(i);

                return Dismissible(
                  key: ValueKey<Token>(token),
                  confirmDismiss: (direction) async {
                    return (await askForConfirmation(
                      context: context,
                      title: Text(
                        AppLocalizations.of(context)!.lltDelete,
                      ),
                      content: Text(
                        AppLocalizations.of(context)!.lltDeleteConfirmation(
                          token.name,
                        ),
                      ),
                    ));
                  },
                  onDismissed: (direction) {
                    cubit.deleteLongLivedToken(
                      token,
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
                        token.name,
                      ),
                      subtitle: token.lastUsedAt != null
                          ? Text(
                              "${AppLocalizations.of(context)!.lastUsed}: ${DateFormat.yMMMEd().add_jm().format(
                                    token.lastUsedAt!,
                                  )}",
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ignore: long-method
  void _createLLTflow(BuildContext context) async {
    final confirm = await askForConfirmation(
      context: context,
      title: Text(
        AppLocalizations.of(context)!.lltWarningTitle,
      ),
      content: Text(
        AppLocalizations.of(context)!.lltWarningContent,
      ),
      confirmText: AppLocalizations.of(context)!.okay,
    );
    if (!confirm) return;

    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return TextDialog(
          title: AppLocalizations.of(context)!.lltCreate,
          doneText: AppLocalizations.of(context)!.add,
          hintText: AppLocalizations.of(context)!.name,
          isInputValid: (s) => s.isNotEmpty,
        );
      },
    );
    if (name == null) return;

    final token = await cubit.addLongLivedToken(name);

    if (token == null || token.isEmpty) return;

    await askForConfirmation(
      context: context,
      showCancel: false,
      confirmText: AppLocalizations.of(context)!.done,
      title: Text(AppLocalizations.of(context)!.lltNotShownAgain),
      content: Row(
        children: [
          Expanded(
            child: SelectableText(token),
          ),
          Builder(builder: (context) {
            return IconButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: token,
                  ),
                );
                Navigator.of(context).pop();
                showSnackbar(
                  context: context,
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .copied,
                  ),
                );
              },
              icon: const Icon(
                Icons.copy_rounded,
              ),
            );
          }),
        ],
      ),
    );
  }
}
