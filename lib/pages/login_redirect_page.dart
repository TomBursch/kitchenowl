import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/splash_page.dart';

class LoginRedirectPage extends StatefulWidget {
  final String? state;
  final String? code;
  const LoginRedirectPage({super.key, this.state, this.code});

  @override
  State<LoginRedirectPage> createState() => _LoginRedirectPageState();
}

class _LoginRedirectPageState extends State<LoginRedirectPage> {
  @override
  void initState() {
    super.initState();
    if (widget.state == null || widget.code == null) {
      showSnackbar(
        context: context,
        content: Text(AppLocalizations.of(context)!.error),
        width: null,
      );
      context.go("/");
    }
    BlocProvider.of<AuthCubit>(context).loginOIDC(
      widget.state!,
      widget.code!,
      (String? msg) => showSnackbar(
        context: context,
        content: Text(
          _extractErrorMessage(context, msg),
        ),
        width: null,
      ),
    );
  }

  String _extractErrorMessage(BuildContext context, String? msg) {
    if (msg == null) return AppLocalizations.of(context)!.error;
    if (msg.contains("email")) return AppLocalizations.of(context)!.emailUsed;
    if (msg.contains("username")) {
      return AppLocalizations.of(context)!.usernameUnavailable;
    }

    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return const SplashPage();
  }
}
