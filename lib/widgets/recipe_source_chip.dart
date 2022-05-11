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
                  avatar: const Icon(
                    Icons.link,
                    color: Colors.white,
                  ),
                  label: Text(
                    snapshot.data!
                        ? Uri.tryParse(source)?.host ?? source
                        : source,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
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
                  avatar: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    source,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  elevation: 3,
                ),
    );
  }
}
