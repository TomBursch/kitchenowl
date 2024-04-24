import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchenowl/kitchenowl.dart';

class CreateUserFormFields extends StatelessWidget {
  final TextEditingController? usernameController;
  final TextEditingController? nameController;
  final TextEditingController? passwordController;
  final TextEditingController? emailController;
  final void Function(BuildContext)? submit;
  final bool enableEmail;

  const CreateUserFormFields({
    super.key,
    this.usernameController,
    this.nameController,
    this.passwordController,
    this.emailController,
    this.submit,
    this.enableEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          TextFormField(
            controller: usernameController,
            autofocus: true,
            autofillHints: const [
              AutofillHints.newUsername,
              AutofillHints.username,
            ],
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            inputFormatters: [
              TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(
                  text: newValue.text.toLowerCase().replaceAll(" ", ""),
                ),
              ),
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.username,
            ),
            validator: (s) {
              if (s == null || s.isEmpty) {
                return AppLocalizations.of(context)!.fieldCannotBeEmpty(
                  AppLocalizations.of(context)!.username,
                );
              }

              if (s.contains("@")) {
                return AppLocalizations.of(context)!.usernameInvalid;
              }

              return null;
            },
          ),
          if (enableEmail)
            TextFormField(
              controller: emailController,
              autofillHints: const [
                AutofillHints.email,
              ],
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.replaceAll(" ", "")),
                ),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email,
              ),
              validator: (s) {
                if (s == null || s.isEmpty) {
                  return AppLocalizations.of(context)!.fieldCannotBeEmpty(
                    AppLocalizations.of(context)!.email,
                  );
                }

                if (!s.contains("@")) {
                  return AppLocalizations.of(context)!.emailInvalid;
                }

                return null;
              },
            ),
          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            autofillHints: const [
              AutofillHints.name,
              AutofillHints.nickname,
            ],
            keyboardType: TextInputType.name,
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
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted:
                submit != null ? (text) => submit!(context) : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
            ),
            validator: (s) {
              if (s == null || s.isEmpty) {
                return AppLocalizations.of(context)!.fieldCannotBeEmpty(
                  AppLocalizations.of(context)!.password,
                );
              }

              if (s.length < 4) {
                return AppLocalizations.of(context)!.passwordFieldTooShort;
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}
