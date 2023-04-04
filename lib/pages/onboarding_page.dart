import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
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
                    const Spacer(),
                    Text(AppLocalizations.of(context)!.onboardingTitle),
                    TextFormField(
                      controller: usernameController,
                      autofocus: true,
                      autofillHints: const [
                        AutofillHints.newUsername,
                        AutofillHints.username,
                      ],
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toLowerCase(),
                          ),
                        ),
                      ],
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
                      textCapitalization: TextCapitalization.sentences,
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
                      onFieldSubmitted: (text) => _submit(context),
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
                        onPressed: () => _submit(context),
                        child: Text(AppLocalizations.of(context)!.start),
                      ),
                    ),
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

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthCubit>(context).onboard(
        username: usernameController.text,
        name: nameController.text,
        password: passwordController.text,
      );
    }
  }
}
