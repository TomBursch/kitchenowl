import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

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
              child: Text(
                "Tutorial",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
