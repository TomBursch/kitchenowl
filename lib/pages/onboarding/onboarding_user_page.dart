import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class OnboardingUserPage extends StatefulWidget {
  final void Function({
    required String username,
    required String name,
    required String password,
  }) next;

  const OnboardingUserPage({Key? key, required this.next}) : super(key: key);

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
    return Form(
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
    );
  }

  void _next(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      widget.next(
        username: usernameController.text,
        name: nameController.text,
        password: passwordController.text,
      );
    }
  }
}
