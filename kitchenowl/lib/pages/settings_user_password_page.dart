import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUserPasswordPage extends StatelessWidget {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordRepeatController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AlignmentGeometry alignment;
  final Future<void> Function(String)? onSubmitt;
  final PreferredSizeWidget? appBar;

  SettingsUserPasswordPage({
    super.key,
    this.onSubmitt,
    this.appBar,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            title: Text(AppLocalizations.of(context)!.passwordSave),
          ),
      extendBodyBehindAppBar: alignment != Alignment.topCenter,
      body: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              children: [
                TextFormField(
                  controller: passwordController,
                  autofillHints: const [
                    AutofillHints.newPassword,
                    AutofillHints.password,
                  ],
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return AppLocalizations.of(context)!.fieldCannotBeEmpty(
                        AppLocalizations.of(context)!.password,
                      );
                    }

                    if (s.length < 4) {
                      return AppLocalizations.of(context)!
                          .passwordFieldTooShort;
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordRepeatController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.passwordRepeat,
                  ),
                  validator: (s) => s != passwordController.text
                      ? AppLocalizations.of(context)!.passwordRepeatNoMatch
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: LoadingElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        return (onSubmitt ??
                            Navigator.of(context).pop)(passwordController.text);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
