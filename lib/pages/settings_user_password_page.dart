import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUserPasswordPage extends StatelessWidget {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordRepeatController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SettingsUserPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.passwordSave),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            TextFormField(
              controller: passwordController,
              autofillHints: const [
                AutofillHints.newPassword,
                AutofillHints.password,
              ],
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (s) => s == null || s.isEmpty
                  ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                      AppLocalizations.of(context)!.password,
                    )
                  : null,
            ),
            TextFormField(
              controller: passwordRepeatController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password, //TODO
              ),
              validator: (s) => s != passwordController.text
                  ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                      AppLocalizations.of(context)!.password,
                    ) //TODO
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.of(context).pop(passwordController.text);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
