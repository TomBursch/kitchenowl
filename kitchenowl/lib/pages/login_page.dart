import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/enums/oidc_provider.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/styles/color_mapper.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (getValueForScreenType(
            context: context,
            mobile: false,
            tablet: false,
            desktop: true,
          ))
            Expanded(
              child: Container(
                child: SvgPicture(
                  SvgAssetLoader(
                    "assets/illustrations/shopping_app.svg",
                    colorMapper: KitchenOwlColorMapper(
                      accentColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  fit: BoxFit.scaleDown,
                ),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: App.settings.accentColor == null &&
                          Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceBright
                      : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          Expanded(
            child: CustomScrollView(
              primary: true,
              slivers: [
                if (!kIsWeb)
                  SliverAppBar(
                    actions: [
                      PopupMenuButton(
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<int>>[
                          PopupMenuItem<int>(
                            value: 0,
                            child: ListTile(
                              leading: const Icon(Icons.swap_horiz_rounded),
                              title: Text(
                                  AppLocalizations.of(context)!.serverChange),
                            ),
                          ),
                        ],
                        onSelected: (_) {
                          BlocProvider.of<AuthCubit>(context).removeServer();
                        },
                      ),
                    ],
                  ),
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Text(
                              AppLocalizations.of(context)!.welcomeBack,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 10),
                            if (!App.isDefaultServer)
                              Text(
                                '${AppLocalizations.of(context)!.loginTo} ${Uri.parse(ApiService.getInstance().baseUrl).authority}',
                              ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: usernameController,
                              autofocus: true,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.username,
                              ),
                            ),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.go,
                              autofillHints: const [AutofillHints.password],
                              keyboardType: TextInputType.visiblePassword,
                              onSubmitted: (value) =>
                                  BlocProvider.of<AuthCubit>(context).login(
                                usernameController.text,
                                passwordController.text,
                                () => showSnackbar(
                                  context: context,
                                  content: Text(AppLocalizations.of(context)!
                                      .wrongUsernameOrPassword),
                                  width: null,
                                ),
                              ),
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.password,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 10),
                              child: LoadingFilledButton(
                                onPressed: () =>
                                    BlocProvider.of<AuthCubit>(context).login(
                                  usernameController.text,
                                  passwordController.text,
                                  () => showSnackbar(
                                    context: context,
                                    content: Text(AppLocalizations.of(context)!
                                        .wrongUsernameOrPassword),
                                    width: null,
                                  ),
                                ),
                                child:
                                    Text(AppLocalizations.of(context)!.login),
                              ),
                            ),
                            if (_displayRegister())
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 100,
                                    child: Divider(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child:
                                        Text(AppLocalizations.of(context)!.or),
                                  ),
                                  const SizedBox(
                                    width: 100,
                                    child: Divider(),
                                  ),
                                ],
                              ),
                            if (_displayRegister())
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 8),
                                child: ElevatedButton(
                                  onPressed: () => context.push("/register"),
                                  child: Text(
                                      AppLocalizations.of(context)!.signup),
                                ),
                              ),
                            const Spacer(),
                            if (App.serverInfo is ConnectedServerInfoState &&
                                (App.serverInfo as ConnectedServerInfoState)
                                    .emailMandatory)
                              TextButton.icon(
                                icon: const Icon(Icons.lock_reset_rounded),
                                label: Text(AppLocalizations.of(context)!
                                    .passwordForgot),
                                onPressed: () =>
                                    context.push("/forgot-password"),
                              ),
                            if (_displayOIDC()) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Divider(),
                              ),
                              if (_providerEnabled(OIDCProivder.custom))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, bottom: 2),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        OIDCProivder.custom.login(context),
                                    icon: OIDCProivder.custom.toIcon(context),
                                    label: Text(AppLocalizations.of(context)!
                                        .signInWith(OIDCProivder.custom
                                            .toLocalizedString())),
                                  ),
                                ),
                              if (_providerEnabled(OIDCProivder.google))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, bottom: 2),
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        OIDCProivder.google.login(context),
                                    icon: OIDCProivder.google.toIcon(context),
                                    label: Text(AppLocalizations.of(context)!
                                        .signInWith(OIDCProivder.google
                                            .toLocalizedString())),
                                  ),
                                ),
                              if (!kIsWeb &&
                                  (Platform.isIOS || Platform.isMacOS) &&
                                  _providerEnabled(OIDCProivder.apple))
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, bottom: 2),
                                  child: LoadingElevatedButtonIcon(
                                    onPressed: () =>
                                        OIDCProivder.apple.login(context),
                                    icon: OIDCProivder.apple.toIcon(context),
                                    label: Text(AppLocalizations.of(context)!
                                        .signInWith(OIDCProivder.apple
                                            .toLocalizedString())),
                                  ),
                                ),
                            ],
                            SizedBox(
                                height:
                                    MediaQuery.paddingOf(context).bottom + 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _displayRegister() =>
      App.serverInfo is ConnectedServerInfoState &&
      (App.serverInfo as ConnectedServerInfoState).openRegistration;

  bool _displayOIDC() =>
      App.serverInfo is ConnectedServerInfoState &&
      (App.serverInfo as ConnectedServerInfoState).oidcProvider.isNotEmpty;

  bool _providerEnabled(OIDCProivder provider) =>
      (App.serverInfo as ConnectedServerInfoState)
          .oidcProvider
          .contains(provider);
}
