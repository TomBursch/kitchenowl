import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/create_user_form_fields.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    const Spacer(),
                    Text(AppLocalizations.of(context)!.onboardingTitle),
                    CreateUserFormFields(
                      usernameController: usernameController,
                      nameController: nameController,
                      passwordController: passwordController,
                      submit: _submit,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: LoadingElevatedButton(
                        onPressed: () => _submit(context),
                        child: Text(AppLocalizations.of(context)!.start),
                      ),
                    ),
                    const Spacer(),
                    if (!kIsWeb)
                      TextButton.icon(
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(AppLocalizations.of(context)!.serverChange),
                        onPressed: () =>
                            BlocProvider.of<AuthCubit>(context).removeServer(),
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

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      await BlocProvider.of<AuthCubit>(context).onboard(
        username: usernameController.text,
        name: nameController.text,
        password: passwordController.text,
        correctCredentialsCallback: () => context.push("/tutorial"),
      );
    }
  }
}
