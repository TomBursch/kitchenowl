import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';

class ItemChip extends StatelessWidget {
  final Item item;
  final String? description;

  const ItemChip({
    super.key,
    required this.item,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    IconData? icon = ItemIcons.get(item);
    return Chip(
      avatar: icon != null ? Icon(icon) : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding:
          icon != null ? const EdgeInsets.only(left: 1, right: 4) : null,
      label: Text(item.name +
          (description != null
              ? description!.isNotEmpty
                  ? " (${_limitString(description!)})"
                  : ""
              : item is ItemWithDescription &&
                      (item as ItemWithDescription).description.isNotEmpty
                  ? " (${_limitString((item as ItemWithDescription).description)})"
                  : "")),
    );
  }

  String _limitString(String s) {
    return s.length > 15 ? "${s.substring(0, math.min(15, s.length))}..." : s;
  }
}
