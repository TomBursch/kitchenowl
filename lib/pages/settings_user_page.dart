import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_user_cubit.dart';
import 'package:kitchenowl/enums/token_type_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/token.dart';

class SettingsUserPage extends StatefulWidget {
  final int? userId;
  const SettingsUserPage({Key? key, this.userId}) : super(key: key);

  @override
  _SettingsUserPageState createState() => _SettingsUserPageState();
}

class _SettingsUserPageState extends State<SettingsUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late SettingsUserCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = SettingsUserCubit(widget.userId);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(cubit.state.updateState);

        return false;
      },
      child: BlocListener<SettingsUserCubit, SettingsUserState>(
        bloc: cubit,
        listener: (context, state) {
          if (state.user != null) {
            usernameController.text = state.user?.username ?? '';
            nameController.text = state.user?.name ?? '';
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.user),
            leading: BackButton(
              onPressed: () =>
                  Navigator.of(context).pop(cubit.state.updateState),
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Icon(
                      Icons.account_circle_rounded,
                      size: 90,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      enabled: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.username,
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.name,
                      ),
                    ),
                    if (cubit.userId != null)
                      BlocBuilder<SettingsUserCubit, SettingsUserState>(
                        bloc: cubit,
                        builder: (context, state) {
                          return ListTile(
                            title: Text(AppLocalizations.of(context)!.admin),
                            leading:
                                const Icon(Icons.admin_panel_settings_rounded),
                            contentPadding:
                                const EdgeInsets.only(left: 0, right: 0),
                            trailing: KitchenOwlSwitch(
                              value: state.setAdmin,
                              onChanged: cubit.setAdmin,
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: LoadingElevatedButton(
                        onPressed: () => cubit.updateUser(
                          context: context,
                          name: nameController.text,
                        ),
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      autofillHints: const [AutofillHints.newPassword],
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: LoadingElevatedButton(
                        onPressed: () => cubit.updateUser(
                          context: context,
                          password: passwordController.text,
                        ),
                        child: Text(AppLocalizations.of(context)!.passwordSave),
                      ),
                    ),
                    BlocBuilder<SettingsUserCubit, SettingsUserState>(
                      bloc: cubit,
                      buildWhen: (prev, curr) =>
                          prev.user?.tokens != curr.user?.tokens,
                      builder: (context, state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: (state.user?.tokens?.isEmpty ?? true)
                            ? const []
                            : [
                                if (state.user!.tokens!
                                    .where(
                                      (e) => e.type == TokenTypeEnum.refresh,
                                    )
                                    .isNotEmpty) ...[
                                  Text(
                                    '${AppLocalizations.of(context)!.sessions}:',
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: state.user?.tokens
                                            ?.where((e) =>
                                                e.type == TokenTypeEnum.refresh)
                                            .length ??
                                        0,
                                    itemBuilder: (context, i) => Card(
                                      child: ListTile(
                                        title: Text(
                                          state.user!.tokens!
                                              .where((e) =>
                                                  e.type ==
                                                  TokenTypeEnum.refresh)
                                              .elementAt(i)
                                              .name,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                TextWithIconButton(
                                  title:
                                      '${AppLocalizations.of(context)!.llts}:',
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _createLLTflow(context),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: state.user?.tokens
                                          ?.where(
                                            (e) =>
                                                e.type ==
                                                TokenTypeEnum.longlived,
                                          )
                                          .length ??
                                      0,
                                  itemBuilder: (context, i) => Dismissible(
                                    key: ValueKey<Token>(state.user!.tokens!
                                        .where(
                                          (e) =>
                                              e.type == TokenTypeEnum.longlived,
                                        )
                                        .elementAt(i)),
                                    confirmDismiss: (direction) async {
                                      return (await askForConfirmation(
                                        context: context,
                                        title: Text(
                                          AppLocalizations.of(context)!
                                              .lltDelete,
                                        ),
                                        content: Text(
                                          AppLocalizations.of(context)!
                                              .lltDeleteConfirmation(
                                            state.user!.tokens!
                                                .where(
                                                  (e) =>
                                                      e.type ==
                                                      TokenTypeEnum.longlived,
                                                )
                                                .elementAt(i)
                                                .name,
                                          ),
                                        ),
                                      ));
                                    },
                                    onDismissed: (direction) {
                                      cubit.deleteLongLivedToken(
                                        state.user!.tokens!
                                            .where(
                                              (e) =>
                                                  e.type ==
                                                  TokenTypeEnum.longlived,
                                            )
                                            .elementAt(i),
                                      );
                                    },
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.red,
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
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.red,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    child: Card(
                                      child: ListTile(
                                        title: Text(
                                          state.user!.tokens!
                                              .where(
                                                (e) =>
                                                    e.type ==
                                                    TokenTypeEnum.longlived,
                                              )
                                              .elementAt(i)
                                              .name,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
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
        );
      },
    );
    if (name == null || name.isEmpty) return;

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
