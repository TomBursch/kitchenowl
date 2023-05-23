import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/create_user_form_fields.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final String? privacyPolicyUrl =
        (App.serverInfo is ConnectedServerInfoState)
            ? (App.serverInfo as ConnectedServerInfoState).privacyPolicyUrl
            : null;

    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
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
                    Text(AppLocalizations.of(context)!.accountCreateTitle),
                    CreateUserFormFields(
                      usernameController: usernameController,
                      nameController: nameController,
                      passwordController: passwordController,
                      submit: _submit,
                    ),
                    if (privacyPolicyUrl != null &&
                        isValidUrl(privacyPolicyUrl))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: MarkdownBody(
                          data:
                              AppLocalizations.of(context)!.privacyPolicyAgree(
                            "[${AppLocalizations.of(context)!.privacyPolicy}]($privacyPolicyUrl)",
                          ),
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.color
                                      ?.withOpacity(.3),
                                ),
                            a: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null && isValidUrl(href)) {
                              openUrl(context, href);
                            }
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ElevatedButton(
                        onPressed: () => _submit(context),
                        child:
                            Text(AppLocalizations.of(context)!.accountCreate),
                      ),
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
      BlocProvider.of<AuthCubit>(context).signup(
        username: usernameController.text,
        name: nameController.text,
        password: passwordController.text,
        wrongCredentialsCallback: () => showSnackbar(
          context: context,
          content: Text(
            AppLocalizations.of(context)!.usernameUnavailable,
          ),
          width: null,
        ),
      );
    }
  }
}
