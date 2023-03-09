import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchenowl/kitchenowl.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(width: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '404',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.pageNotFound,
                maxLines: null,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:
                    context.canPop() ? context.pop : () => context.go("/"),
                child: Text(AppLocalizations.of(context)!.back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
