import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/debouncer.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:responsive_builder/responsive_builder.dart';

class KitchenowlSearchAnchor extends StatefulWidget {
  final FutureOr<Iterable<String>> Function(BuildContext, SearchController)
      suggestionsBuilder;
  final void Function(String) onSearch;

  /// Search dealy in milliseconds.
  /// Set it to 0 to remove the debouncer
  final int searchDelay;

  const KitchenowlSearchAnchor({
    super.key,
    required this.suggestionsBuilder,
    required this.onSearch,
    this.searchDelay = 200,
  });

  @override
  State<KitchenowlSearchAnchor> createState() => _KitchenowlSearchAnchorState();
}

class _KitchenowlSearchAnchorState extends State<KitchenowlSearchAnchor> {
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
    return SearchAnchor(
      searchController: controller,
      isFullScreen: getValueForScreenType<bool>(
        context: context,
        mobile: true,
        tablet: true,
        desktop: false,
      ),
      viewBackgroundColor: getValueForScreenType<Color?>(
        context: context,
        mobile: Theme.of(context).scaffoldBackgroundColor,
        tablet: Theme.of(context).scaffoldBackgroundColor,
        desktop: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      textInputAction: TextInputAction.search,
      viewHintText: AppLocalizations.of(context)!.searchHint,
      textCapitalization: TextCapitalization.sentences,
      viewOnSubmitted: (value) {
        controller.closeView(null);
      },
      viewConstraints:
          BoxConstraints(minWidth: 360.0, minHeight: 240.0, maxHeight: 350),
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
      suggestionsBuilder: (context, controller) async =>
          (await widget.suggestionsBuilder(context, controller)).map(
        (e) => ListTile(
          title: Text(e),
          onTap: () {
            controller.closeView(e);
          },
        ),
      ),
    );
  }
}
