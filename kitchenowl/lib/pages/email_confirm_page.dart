import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/email_confirm_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class EmailConfirmPage extends StatefulWidget {
  final String? token;
  const EmailConfirmPage({super.key, this.token});

  @override
  State<EmailConfirmPage> createState() => _EmailConfirmPageState();
}

class _EmailConfirmPageState extends State<EmailConfirmPage> {
  late EmailConfirmCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = EmailConfirmCubit(widget.token);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? null
            : BackButton(
                onPressed: () => context.go("/"),
              ),
      ),
      body: Center(
        child: BlocBuilder(
            bloc: cubit,
            builder: (context, state) {
              if (state is EmailConfirmSuccessState) {
                return Text(
                    AppLocalizations.of(context)!.emailSuccessfullyVerified);
              }
              if (state is EmailConfirmErrorState) {
                return Text(AppLocalizations.of(context)!.error);
              }
              return const CircularProgressIndicator();
            }),
      ),
    );
  }
}
