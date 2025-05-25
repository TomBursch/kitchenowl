import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';

class KitchenowlPersistentSearchAnchor extends StatefulWidget {
  final FutureOr<Iterable<String>> Function(BuildContext, SearchController)
      suggestionsBuilder;
  final void Function(String) onSearch;

  /// Search dealy in milliseconds.
  /// Set it to 0 to remove the debouncer
  final int searchDelay;

  const KitchenowlPersistentSearchAnchor({
    super.key,
    required this.suggestionsBuilder,
    required this.onSearch,
    this.searchDelay = 200,
  });

  @override
  State<KitchenowlPersistentSearchAnchor> createState() =>
      _KitchenowlPersistentSearchAnchorState();
}

class _KitchenowlPersistentSearchAnchorState
    extends State<KitchenowlPersistentSearchAnchor> {
  final SearchController controller = SearchController();
  String search = "";
  Debouncer? _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer =
        Debouncer(duration: Duration(milliseconds: widget.searchDelay));
    controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final String s = controller.text;
    if (search.isNotEmpty && s.isEmpty) controller.closeView(null);
    if (_debouncer != null) {
      _debouncer?.run(() {
        setState(() {
          search = s;
        });
        widget.onSearch(s);
      });
    } else {
      setState(() {
        search = s;
      });
      widget.onSearch(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KitchenowlSearchAnchor(
      searchController: controller,
      viewOnSubmitted: (value) {
        controller.closeView(value);
      },
      builder: (BuildContext context, SearchController controller) {
        if (search.isEmpty)
          return IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              controller.openView();
            },
          );

        return FilledButton.tonalIcon(
          onPressed: () {
            controller.openView();
          },
          label: Text(search),
          icon: Icon(Icons.search_rounded),
        );
      },
      suggestionsBuilder: widget.suggestionsBuilder,
    );
  }
}
