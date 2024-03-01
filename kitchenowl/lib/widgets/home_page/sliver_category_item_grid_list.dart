import 'package:flutter/material.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverCategoryItemGridList<T extends Item> extends StatefulWidget {
  final String name;
  final Duration animationDuration;

  // SliverItemGridList
  final void Function()? onRefresh;
  final Nullable<void Function(T)>? onPressed;
  final Nullable<void Function(T)>? onLongPressed;
  final List<T> items;
  final List<Category>? categories; // forwarded to item page on long press
  final ShoppingList? shoppingList; // forwarded to item page on long press
  final bool Function(T)? selected;
  final bool isLoading;
  final bool? allRaised;
  final Widget Function(T)? extraOption;
  final bool isSubTitle;
  final bool splitByCategories;

  const SliverCategoryItemGridList({
    super.key,
    required this.name,
    this.animationDuration = const Duration(milliseconds: 150),
    this.onRefresh,
    this.onPressed,
    this.onLongPressed,
    this.items = const [],
    this.categories,
    this.shoppingList,
    this.selected,
    this.isLoading = false,
    this.allRaised,
    this.extraOption,
    this.isSubTitle = false,
    this.splitByCategories = false,
  });

  @override
  State<SliverCategoryItemGridList<T>> createState() =>
      _SliverCategoryItemGridListState<T>();
}

class _SliverCategoryItemGridListState<T extends Item>
    extends State<SliverCategoryItemGridList<T>> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    TextStyle? titleTextStyle = Theme.of(context).textTheme.titleLarge;
    if (widget.isSubTitle)
      titleTextStyle = titleTextStyle?.apply(fontStyle: FontStyle.italic, fontWeightDelta: -1);

    List<Widget> list = [];
    final categoryLength = widget.categories?.length ?? 0;

    if (widget.splitByCategories) {
      for (int i = 0; i < categoryLength + 1; i++) {
        Category? category = i < categoryLength
            ? widget.categories![i]
            : null;
        final List<T> items = widget.items
            .where((e) => e.category == category)
            .toList();
        if (items.isEmpty) continue;

        list.add(SliverCategoryItemGridList(
          name: category?.name ??
              AppLocalizations.of(context)!.uncategorized,
          items: items,
          categories: widget.categories,
          shoppingList: widget.shoppingList,
          selected: widget.selected,
          isLoading: widget.isLoading,
          onRefresh: widget.onRefresh,
          onPressed: widget.onPressed,
          isSubTitle: true,
          allRaised: widget.allRaised,
          extraOption: widget.extraOption,
        ));
      }
    }
    else
      list.add(SliverItemGridList<T>(
        onRefresh: widget.onRefresh,
        onPressed: widget.onPressed,
        onLongPressed: widget.onLongPressed,
        items: widget.items,
        categories: widget.categories,
        shoppingList: widget.shoppingList,
        selected: widget.selected,
        isLoading: widget.isLoading,
        allRaised: widget.allRaised,
        extraOption: widget.extraOption,
      ));

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: AnimatedPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, isExpanded ? 8 : 4),
            duration: widget.animationDuration,
            child: InkWell(
              onTap: () => setState(() {
                isExpanded = !isExpanded;
              }),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      style: titleTextStyle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      isExpanded = !isExpanded;
                    }),
                    icon: AnimatedRotation(
                      duration: widget.animationDuration,
                      turns: isExpanded ? 0 : .25,
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverAnimatedSwitcher(
          duration: widget.animationDuration,
          child: !isExpanded
              ? const SliverToBoxAdapter(child: SizedBox())
              : MultiSliver(children: list),
        ),
      ],
    );
  }
}
