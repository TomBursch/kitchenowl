import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _setupDefault,
        ),
      ),
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
                    Text(AppLocalizations.of(context)!.setupTitle),
                    TextFormField(
                      controller: urlController,
                      autofillHints: const [AutofillHints.url],
                      textInputAction: TextInputAction.go,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      autocorrect: false,
                      keyboardType: TextInputType.url,
                      onFieldSubmitted: (text) => _setup(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.address,
                        hintText: 'https://localhost',
                      ),
                      validator: (s) => s == null || s.isEmpty
                          ? AppLocalizations.of(context)!.fieldCannotBeEmpty(
                              AppLocalizations.of(context)!.address,
                            )
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: ElevatedButton(
                        onPressed: _setup,
                        child: Text(AppLocalizations.of(context)!.go),
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

  void _setup() {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthCubit>(context).setupServer(urlController.text);
    }
  }

  void _setupDefault() {
    BlocProvider.of<AuthCubit>(context).setupDefaultServer();
  }
}
