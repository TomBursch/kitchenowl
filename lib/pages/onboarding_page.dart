import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.onboardingTitle),
                  TextField(
                    controller: usernameController,
                    autofocus: true,
                    autofillHints: const [
                      AutofillHints.newUsername,
                      AutofillHints.username,
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.username,
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.name,
                      AutofillHints.nickname,
                    ],
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofillHints: const [
                      AutofillHints.newPassword,
                      AutofillHints.password,
                    ],
                    textInputAction: TextInputAction.go,
                    onSubmitted: (text) =>
                        BlocProvider.of<AuthCubit>(context).createUser(
                      usernameController.text,
                      nameController.text,
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
                          BlocProvider.of<AuthCubit>(context).createUser(
                        usernameController.text,
                        nameController.text,
                        passwordController.text,
                      ),
                      child: Text(AppLocalizations.of(context)!.start),
                    ),
                  ),
                  if (!kIsWeb) Text(AppLocalizations.of(context)!.or),
                  if (!kIsWeb)
                    TextButton(
                      onPressed: () =>
                          BlocProvider.of<AuthCubit>(context).removeServer(),
                      child: Text(AppLocalizations.of(context)!.serverChange),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
