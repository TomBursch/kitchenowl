import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RecipeSourceChip extends StatelessWidget {
  final String source;
  const RecipeSourceChip({Key? key, required this.source}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: canLaunchUrlString(source),
      initialData: false,
      builder: (
        context,
        AsyncSnapshot<bool> snapshot,
      ) =>
          snapshot.data!
              ? ActionChip(
                  avatar: Icon(
                    Icons.link,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    snapshot.data!
                        ? Uri.tryParse(source)?.host ?? source
                        : source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 3,
                  onPressed: () async {
                    if (await canLaunchUrlString(
                      source,
                    )) {
                      await launchUrlString(
                        source,
                      );
                    }
                  },
                )
              : Chip(
                  avatar: Icon(
                    Icons.book_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 3,
                ),
    );
  }
}
