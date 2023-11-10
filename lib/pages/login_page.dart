import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      extendBodyBehindAppBar: true,
      appBar: !kIsWeb
          ? AppBar(
              actions: [
                PopupMenuButton(
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    PopupMenuItem<int>(
                      value: 0,
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz_rounded),
                        title: Text(AppLocalizations.of(context)!.serverChange),
                      ),
                    ),
                  ],
                  onSelected: (_) {
                    BlocProvider.of<AuthCubit>(context).removeServer();
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      '${AppLocalizations.of(context)!.loginTo} ${Uri.parse(ApiService.getInstance().baseUrl).authority}',
                    ),
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.username,
                      ),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.go,
                      autofillHints: const [AutofillHints.password],
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
                        labelText: AppLocalizations.of(context)!.password,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 10),
                      child: LoadingElevatedButton(
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
                        child: Text(AppLocalizations.of(context)!.login),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(AppLocalizations.of(context)!.or),
                          ),
                          const SizedBox(
                            width: 100,
                            child: Divider(),
                          ),
                        ],
                      ),
                    if (_displayRegister())
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: ElevatedButton(
                          onPressed: () => context.push("/register"),
                          child: Text(AppLocalizations.of(context)!.signup),
                        ),
                      ),
                    const Spacer(),
                    if (App.serverInfo is ConnectedServerInfoState &&
                        (App.serverInfo as ConnectedServerInfoState)
                            .emailMandatory)
                      TextButton.icon(
                        icon: const Icon(Icons.lock_reset_rounded),
                        label:
                            Text(AppLocalizations.of(context)!.passwordForgot),
                        onPressed: () => context.push("/forgot-password"),
                      ),
                    if (_displayOIDC()) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Divider(),
                      ),
                      if (_providerEnabled("custom"))
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 2),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = (await ApiService.getInstance()
                                      .getLoginOIDCUrl())
                                  .$1;
                              if (url != null) openUrl(context, url);
                            },
                            icon: const Icon(Icons.turn_slight_left_outlined),
                            label: Text(AppLocalizations.of(context)!
                                .signInWith("OIDC")),
                          ),
                        ),
                      if (_providerEnabled("google"))
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 2),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = (await ApiService.getInstance()
                                      .getLoginOIDCUrl("google"))
                                  .$1;
                              if (url != null) openUrl(context, url);
                            },
                            icon: const Image(
                              image:
                                  AssetImage('assets/images/google_logo.png'),
                              height: 32,
                            ),
                            label: Text(AppLocalizations.of(context)!
                                .signInWith("Google")),
                          ),
                        ),
                      if (!kIsWeb &&
                          (Platform.isIOS || Platform.isMacOS) &&
                          _providerEnabled("apple"))
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 2),
                          child: LoadingElevatedButtonIcon(
                            onPressed: () async {
                              final res = await ApiService.getInstance()
                                  .getLoginOIDCUrl("apple");
                              if (res.$2 == null || res.$3 == null) return;
                              try {
                                final credential =
                                    await SignInWithApple.getAppleIDCredential(
                                  scopes: [
                                    AppleIDAuthorizationScopes.email,
                                    AppleIDAuthorizationScopes.fullName,
                                  ],
                                  state: res.$2,
                                  nonce: res.$3,
                                );
                                BlocProvider.of<AuthCubit>(context).loginOIDC(
                                  credential.state!,
                                  credential.authorizationCode,
                                  (message) => showSnackbar(
                                    context: context,
                                    content: Text(
                                        AppLocalizations.of(context)!.error),
                                    width: null,
                                  ),
                                );
                              } catch (_) {
                                showSnackbar(
                                  context: context,
                                  content:
                                      Text(AppLocalizations.of(context)!.error),
                                  width: null,
                                );
                              }
                            },
                            icon: const Icon(Icons.apple_rounded),
                            label: Text(AppLocalizations.of(context)!
                                .signInWith("Apple")),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _displayRegister() =>
      App.serverInfo is ConnectedServerInfoState &&
      (App.serverInfo as ConnectedServerInfoState).openRegistration;

  bool _displayOIDC() =>
      App.serverInfo is ConnectedServerInfoState &&
      (App.serverInfo as ConnectedServerInfoState).oidcProvider.isNotEmpty &&
      (kIsWeb || Platform.isAndroid || Platform.isLinux);

  bool _providerEnabled(String provider) =>
      (App.serverInfo as ConnectedServerInfoState)
          .oidcProvider
          .contains(provider);
}
