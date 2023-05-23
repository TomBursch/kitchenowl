import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      child: ElevatedButton(
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
                    if (App.serverInfo is ConnectedServerInfoState &&
                        (App.serverInfo as ConnectedServerInfoState)
                            .openRegistration) ...[
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
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: ElevatedButton(
                          onPressed: () => context.push("/register"),
                          child: Text(AppLocalizations.of(context)!.signup),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!kIsWeb)
                      TextButton.icon(
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(AppLocalizations.of(context)!.serverChange),
                        onPressed: () =>
                            BlocProvider.of<AuthCubit>(context).removeServer(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
