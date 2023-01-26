import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';

class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: Navigator.of(context).pop,
              child: Text(AppLocalizations.of(context)!.back),
            ),
          ],
        ),
      ),
    );
  }
}
