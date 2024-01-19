import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/settings_user_email_page.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class PasswordForgotPage extends StatefulWidget {
  const PasswordForgotPage({super.key});

  @override
  State<PasswordForgotPage> createState() => _PasswordForgotPageState();
}

class _PasswordForgotPageState extends State<PasswordForgotPage> {
  @override
  Widget build(BuildContext context) {
    return SettingsUserEmailPage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? null
            : BackButton(
                onPressed: () => context.go("/"),
              ),
      ),
      alignment: Alignment.center,
      buttonText: AppLocalizations.of(context)!.passwordReset,
      onSubmitt: (email) async {
        if (await ApiService.getInstance().forgotPassword(email)) {
          showSnackbar(
            context: context,
            content: Text(AppLocalizations.of(context)!.done),
          );
        } else {
          showSnackbar(
            context: context,
            content: Text(AppLocalizations.of(context)!.error),
          );
        }
        if (mounted) context.go("/");
      },
    );
  }
}
