import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SettingsUserEmailPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final AlignmentGeometry alignment;
  final Future<void> Function(String)? onSubmitt;
  final PreferredSizeWidget? appBar;
  final String? buttonText;

  SettingsUserEmailPage({
    super.key,
    this.alignment = Alignment.topCenter,
    this.onSubmitt,
    this.appBar,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            title: Text(AppLocalizations.of(context)!.emailUpdate),
          ),
      extendBodyBehindAppBar: alignment != Alignment.topCenter,
      body: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
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
                        text: newValue.text.replaceAll(" ", ""),
                      ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: LoadingElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        return (onSubmitt ??
                            Navigator.of(context).pop)(emailController.text);
                      }
                    },
                    child:
                        Text(buttonText ?? AppLocalizations.of(context)!.save),
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
