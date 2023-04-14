import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchenowl/kitchenowl.dart';

class CreateUserFormFields extends StatelessWidget {
  final TextEditingController? usernameController;
  final TextEditingController? nameController;
  final TextEditingController? passwordController;
  final void Function(BuildContext)? submit;

  const CreateUserFormFields({
    super.key,
    this.usernameController,
    this.nameController,
    this.passwordController,
    this.submit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          onFieldSubmitted: submit != null ? (text) => submit!(context) : null,
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
    );
  }
}
