import 'package:flutter/material.dart';
import 'package:kitchenowl/helpers/category_icon.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/styles/dynamic.dart';
import 'package:kitchenowl/widgets/selectable_button_card.dart';
import 'package:kitchenowl/widgets/selectable_button_list_tile.dart';

class ShoppingItemWidget<T extends Item> extends StatelessWidget {
  final T item;
  final void Function(T)? onPressed;
  final void Function(T)? onLongPressed;
  final bool selected;
  final Widget? extraOption;

  /// Only applicable if gridStyle = false, raises the list items and makes them fully opaque.
  /// defaults to true for item is ShoppinglistItem || item is RecipeItem && selected
  final bool? raised;
  final bool gridStyle;
  final ListStyle listStyle;

  /// Show the category emoji as leading icon when the item has no icon.
  final bool showCategoryIcon;

  const ShoppingItemWidget({
    super.key,
    required this.item,
    this.onPressed,
    this.onLongPressed,
    this.selected = false,
    this.gridStyle = true,
    this.listStyle = ListStyle.cards,
    this.raised,
    this.extraOption,
    this.showCategoryIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // When the category-icon setting is on, the category emoji takes
    // precedence over the item's own icon (most common groceries have
    // built-in icons that would otherwise mask the emoji entirely).
    // Selection check / checkbox still win — those are interaction states.
    final String? emojiIcon = showCategoryIcon
        ? categoryEmoji(item.category?.name)
        : null;
    final IconData? icon =
        emojiIcon == null ? ItemIcons.get(item) : null;
    return gridStyle
        ? SelectableButtonCard(
            title: item.name,
            selected: selected,
            icon: icon,
            emojiIcon: emojiIcon,
            description: (item is ItemWithDescription)
                ? (item as ItemWithDescription).description
                : null,
            onPressed: onPressed != null ? () => onPressed!(item) : null,
            onLongPressed:
                onLongPressed != null ? () => onLongPressed!(item) : null,
            extraOption: extraOption,
          )
        : SelectableButtonListTile(
            title: item.name,
            selected: selected,
            icon: icon,
            emojiIcon: emojiIcon,
            listStyle: listStyle,
            raised: raised ??
                item is ShoppinglistItem || item is RecipeItem && selected,
            description: (item is ItemWithDescription)
                ? (item as ItemWithDescription).description
                : null,
            onPressed: onPressed != null ? () => onPressed!(item) : null,
            onLongPressed:
                onLongPressed != null ? () => onLongPressed!(item) : null,
            extraOption: extraOption,
          );
  }
}
