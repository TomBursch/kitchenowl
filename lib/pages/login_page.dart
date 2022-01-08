import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/kitchenowl.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({Key? key}) : super(key: key);

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
                    Text(AppLocalizations.of(context)!.loginTo +
                        ' ${Uri.parse(ApiService.getInstance().baseUrl).authority}'),
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
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
                      ),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ElevatedButton(
                        onPressed: () =>
                            BlocProvider.of<AuthCubit>(context).login(
                          usernameController.text,
                          passwordController.text,
                        ),
                        child: Text(AppLocalizations.of(context)!.login),
                      ),
                    ),
                    if (!kIsWeb) Text(AppLocalizations.of(context)!.or),
                    if (!kIsWeb)
                      TextButton(
                        onPressed: () =>
                            BlocProvider.of<AuthCubit>(context).removeServer(),
                        child: Text(AppLocalizations.of(context)!.serverChange),
                      )
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
