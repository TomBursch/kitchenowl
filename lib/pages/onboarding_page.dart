import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class OnboardingPage extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppLocalizations.of(context).onboardingTitle),
              TextField(
                controller: usernameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).username,
                ),
              ),
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).name,
                ),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.go,
                onSubmitted: (text) =>
                    BlocProvider.of<AuthCubit>(context).createUser(
                  usernameController.text,
                  nameController.text,
                  passwordController.text,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).password,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: ElevatedButton(
                  onPressed: () =>
                      BlocProvider.of<AuthCubit>(context).createUser(
                    usernameController.text,
                    nameController.text,
                    passwordController.text,
                  ),
                  child: Text(AppLocalizations.of(context).start),
                ),
              ),
              Text(AppLocalizations.of(context).or),
              TextButton(
                onPressed: () =>
                    BlocProvider.of<AuthCubit>(context).removeServer(),
                child: Text(AppLocalizations.of(context).serverChange),
              )
            ],
          ),
        ),
      ),
    );
  }
}
