import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/server_settings.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class OnboardingSettingsPage extends StatefulWidget {
  final String username;
  final String name;
  final String password;
  final void Function() back;

  const OnboardingSettingsPage({
    Key? key,
    required this.username,
    required this.name,
    required this.password,
    required this.back,
  }) : super(key: key);

  @override
  State<OnboardingSettingsPage> createState() => _OnboardingSettingsPageState();
}

class _OnboardingSettingsPageState extends State<OnboardingSettingsPage> {
  bool featurePlanner = true;
  bool featureExpenses = false;
  String? language;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: BackButton(
                  onPressed: widget.back,
                ),
              ),
            ),
            Text(AppLocalizations.of(context)!
                .onboardingSettingsTitle(widget.name)),
          ],
        ),
        const SizedBox(height: 15),
        ListTile(
          title: Text(AppLocalizations.of(context)!.mealPlanner),
          leading: const Icon(Icons.calendar_today_rounded),
          contentPadding: const EdgeInsets.only(left: 20, right: 0),
          trailing: KitchenOwlSwitch(
            value: featurePlanner,
            onChanged: (value) => setState(() {
              featurePlanner = value;
            }),
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.balances),
          leading: const Icon(Icons.account_balance_rounded),
          contentPadding: const EdgeInsets.only(left: 20, right: 0),
          trailing: KitchenOwlSwitch(
            value: featureExpenses,
            onChanged: (value) => setState(() {
              featureExpenses = value;
            }),
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.language),
          leading: const Icon(Icons.language_rounded),
          contentPadding: const EdgeInsets.only(left: 20, right: 5),
          trailing: FutureBuilder<Map<String, String>?>(
            initialData: const {},
            future: ApiService.getInstance().getSupportedLanguages(),
            builder: (context, snapshot) {
              return DropdownButton<String?>(
                value: language,
                items: [
                  for (final e in (snapshot.data?.entries ??
                      const <MapEntry<String, String>>[]))
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.other),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    language = value;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: ElevatedButton(
            onPressed: () {
              BlocProvider.of<AuthCubit>(context).onboard(
                username: widget.username,
                name: widget.name,
                password: widget.password,
                settings: const ServerSettings(),
                language: language,
              );
            },
            child: Text(AppLocalizations.of(context)!.start),
          ),
        ),
      ],
    );
  }
}
