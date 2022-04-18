import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/onboarding_settings_page.dart';

class OnboardingUserPage extends StatefulWidget {
  const OnboardingUserPage({Key? key}) : super(key: key);

  @override
  State<OnboardingUserPage> createState() => _OnboardingUserPageState();
}

class _OnboardingUserPageState extends State<OnboardingUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.onboardingTitle),
                    TextFormField(
                      controller: usernameController,
                      autofocus: true,
                      autofillHints: const [
                        AutofillHints.newUsername,
                        AutofillHints.username,
                      ],
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.username,
                      ),
                      validator: (s) => s == null || s.isEmpty
                          ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                              AppLocalizations.of(context)!.username,
                            )
                          : null,
                    ),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      autofillHints: const [
                        AutofillHints.name,
                        AutofillHints.nickname,
                      ],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.name,
                      ),
                      validator: (s) => s == null || s.isEmpty
                          ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                              AppLocalizations.of(context)!.name,
                            )
                          : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [
                        AutofillHints.newPassword,
                        AutofillHints.password,
                      ],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (text) => _next(context),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                      ),
                      validator: (s) => s == null || s.isEmpty
                          ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                              AppLocalizations.of(context)!.password,
                            )
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ElevatedButton(
                        onPressed: () => _next(context),
                        child: Text(AppLocalizations.of(context)!.next),
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
      ),
    );
  }

  void _next(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => OnboardingSettingsPage(
          username: usernameController.text,
          name: nameController.text,
          password: passwordController.text,
        ),
      ));
    }
  }
}
