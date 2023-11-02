import 'package:flutter/material.dart';
import 'package:kitchenowl/item_icons.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/nullable.dart';
import 'package:kitchenowl/widgets/search_text_field.dart';
import 'package:kitchenowl/widgets/sliver_item_grid_list.dart';

class IconSelectionPage extends StatefulWidget {
  final String? oldIcon;
  final String name;

  const IconSelectionPage({
    super.key,
    this.oldIcon,
    required this.name,
  });

  @override
  State<IconSelectionPage> createState() => _IconSelectionPageState();
}

class _IconSelectionPageState extends State<IconSelectionPage> {
  TextEditingController searchController = TextEditingController();
  String filter = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: SearchTextField(
                  controller: searchController,
                  clearOnSubmit: false,
                  onSearch: (s) async {
                    setState(() => filter = s.toLowerCase());
                  },
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
          ),
          SliverItemGridList(
            items: ItemIcons.map.keys
                .where((e) => e.contains(filter))
                .map((e) => Item(name: e, icon: e))
                .toList(),
            selected: (item) => item.icon == widget.oldIcon,
            onLongPressed: const Nullable<void Function(Item)>.empty(),
            onPressed: (Item item) {
              if (item.icon == widget.oldIcon) {
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
