import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/settings_server_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/create_user_form_fields.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userAdd),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 600),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CreateUserFormFields(
                          usernameController: usernameController,
                          nameController: nameController,
                          passwordController: passwordController,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: LoadingElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await BlocProvider.of<SettingsServerCubit>(
                                  context,
                                ).createUser(
                                  usernameController.text,
                                  nameController.text,
                                  passwordController.text,
                                );
                                if (!mounted) return;
                                Navigator.of(context).pop(UpdateEnum.updated);
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.userAdd),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
