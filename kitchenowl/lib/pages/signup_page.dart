import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/server_info_cubit.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/router.dart';
import 'package:kitchenowl/styles/color_mapper.dart';
import 'package:kitchenowl/widgets/create_user_form_fields.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final String? privacyPolicyUrl =
        (App.serverInfo is ConnectedServerInfoState)
            ? (App.serverInfo as ConnectedServerInfoState).privacyPolicyUrl
            : null;
    final bool emailMandatory = (App.serverInfo is ConnectedServerInfoState)
        ? (App.serverInfo as ConnectedServerInfoState).emailMandatory
        : false;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (getValueForScreenType(
            context: context,
            mobile: false,
            tablet: false,
            desktop: true,
          ))
            Expanded(
              child: Container(
                child: SvgPicture(
                  SvgAssetLoader(
                    "assets/illustrations/welcoming.svg",
                    colorMapper: KitchenOwlColorMapper(
                      accentColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  fit: BoxFit.scaleDown,
                ),
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: App.settings.accentColor == null &&
                          Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceBright
                      : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          Expanded(
            child: CustomScrollView(
              primary: true,
              slivers: [
                SliverAppBar(
                  leading: Navigator.canPop(context)
                      ? null
                      : BackButton(
                          onPressed: () => context.go("/"),
                        ),
                ),
                SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 600,
                  child: SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.accountCreateTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              AppLocalizations.of(context)!.accountCreateHint,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.color
                                        ?.withOpacity(0.8),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            CreateUserFormFields(
                              usernameController: usernameController,
                              nameController: nameController,
                              passwordController: passwordController,
                              emailController: emailController,
                              enableEmail: emailMandatory,
                            ),
                            if (privacyPolicyUrl != null &&
                                isValidUrl(privacyPolicyUrl))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: MarkdownBody(
                                  data: AppLocalizations.of(context)!
                                      .privacyPolicyAgree(
                                    "[${AppLocalizations.of(context)!.privacyPolicy}]($privacyPolicyUrl)",
                                  ),
                                  shrinkWrap: true,
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.color
                                              ?.withOpacity(.3),
                                        ),
                                    a: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: LoadingFilledButton(
                                onPressed: () => _submit(context),
                                child: Text(AppLocalizations.of(context)!
                                    .accountCreate),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery.paddingOf(context).bottom),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      return BlocProvider.of<AuthCubit>(context).signup(
        username: usernameController.text,
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        wrongCredentialsCallback: (msg) {
          showSnackbar(
            context: context,
            content: Text(
              _extractErrorMessage(context, msg),
            ),
            width: null,
          );
          Future.delayed(
              Duration(milliseconds: 1), () => router.go("/register"));
        },
      );
    }
  }

  String _extractErrorMessage(BuildContext context, String? msg) {
    if (msg == null) return AppLocalizations.of(context)!.error;
    if (msg.contains("email")) return AppLocalizations.of(context)!.emailUsed;
    if (msg.contains("username")) {
      return AppLocalizations.of(context)!.usernameUnavailable;
    }

    return msg;
  }
}
