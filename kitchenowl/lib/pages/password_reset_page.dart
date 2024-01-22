import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/password_reset_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/pages/settings_user_password_page.dart';

class PasswordResetPage extends StatefulWidget {
  final String? token;
  const PasswordResetPage({super.key, this.token});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  late PasswordResetCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = PasswordResetCubit(widget.token);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      bloc: cubit,
      listener: (context, state) {
        if (state is PasswordResetSuccessState) {
          showSnackbar(
            context: context,
            content: Text(AppLocalizations.of(context)!.done),
          );
          if (mounted) context.go("/");
        }
      },
      builder: (context, state) {
        if (state is PasswordResetErrorState) {
          return Scaffold(
            appBar: AppBar(
              leading: Navigator.canPop(context)
                  ? null
                  : BackButton(
                      onPressed: () => context.go("/"),
                    ),
            ),
            body: Center(
              child: Text(AppLocalizations.of(context)!.error),
            ),
          );
        }
        return SettingsUserPasswordPage(
          appBar: AppBar(
            leading: Navigator.canPop(context)
                ? null
                : BackButton(
                    onPressed: () => context.go("/"),
                  ),
          ),
          alignment: Alignment.center,
          onSubmitt: (password) => cubit.resetPassword(password),
        );
      },
    );
  }
}
