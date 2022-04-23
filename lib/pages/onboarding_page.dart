import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:kitchenowl/pages/onboarding/onboarding_settings_page.dart';
import 'package:kitchenowl/pages/onboarding/onboarding_user_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  bool _reverse = false;

  String _username = '';
  String _password = '';
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        reverse: _reverse,
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            child: child,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
          );
        },
        child: SafeArea(
          key: ValueKey(_step),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 600),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _step == 0
                    ? OnboardingUserPage(
                        next: _next,
                      )
                    : OnboardingSettingsPage(
                        username: _username,
                        name: _name,
                        password: _password,
                        back: _back,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _next({
    required String username,
    required String name,
    required String password,
  }) {
    _username = username;
    _name = name;
    _password = password;
    setState(() {
      _reverse = false;
      _step = 1;
    });
  }

  void _back() {
    setState(() {
      _reverse = true;
      _step = 0;
    });
  }
}
