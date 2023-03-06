import 'package:flutter/material.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/nullable.dart';
import 'package:kitchenowl/widgets/sliver_item_grid_list.dart';

class IconSelectionPage extends StatelessWidget {
  final String? oldIcon;
  final String name;

  const IconSelectionPage({
    super.key,
    this.oldIcon,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: CustomScrollView(
        slivers: [
          SliverItemGridList(
            items:
                ItemIcons.map.keys.map((e) => Item(name: e, icon: e)).toList(),
            selected: (item) => item.icon == oldIcon,
            onPressed: (Item item) {
              if (item.icon == oldIcon) {
                Navigator.of(context).pop(const Nullable<String?>.empty());
              } else {
                Navigator.of(context).pop(Nullable(item.icon));
              }
            },
          ),
        ],
      ),
    );
  }
}
