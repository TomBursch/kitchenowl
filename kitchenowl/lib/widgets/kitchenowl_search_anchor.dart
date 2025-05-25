import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:responsive_builder/responsive_builder.dart';

class KitchenowlSearchAnchor extends StatelessWidget {
  final FutureOr<Iterable<String>> Function(BuildContext, SearchController)
      suggestionsBuilder;
  final SearchController? searchController;
  final Function(String)? viewOnSubmitted;
  final Widget Function(BuildContext, SearchController)? builder;
  final String? tooltip;

  const KitchenowlSearchAnchor({
    super.key,
    required this.suggestionsBuilder,
    this.searchController,
    this.viewOnSubmitted,
    this.builder,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: searchController,
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
      viewOnSubmitted: viewOnSubmitted,
      viewOnClose: () {},
      viewConstraints:
          BoxConstraints(minWidth: 360.0, minHeight: 240.0, maxHeight: 350),
      builder: builder ??
          (BuildContext context, SearchController controller) {
            return IconButton(
              icon: const Icon(Icons.search),
              tooltip: tooltip ?? AppLocalizations.of(context)!.search,
              onPressed: () {
                controller.openView();
              },
            );
          },
      suggestionsBuilder: (context, controller) async =>
          (await suggestionsBuilder(context, controller)).map(
        (e) => ListTile(
          title: Text(e),
          onTap: () {
            controller.text = e;
            if (viewOnSubmitted != null) {
              viewOnSubmitted!(e);
            }
          },
        ),
      ),
    );
  }
}
