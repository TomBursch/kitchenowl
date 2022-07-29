import 'package:flutter/material.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/pages/item_page.dart';
import 'package:kitchenowl/pages/item_search_page.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

class StringItemMatch extends StatelessWidget {
  final String string;
  final RecipeItem? item;
  final void Function(RecipeItem?) itemSelected;
  final bool optional;

  StringItemMatch({
    Key? key,
    required this.itemSelected,
    required this.string,
    this.item,
  })  : optional = item?.optional ?? false,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(string),
          contentPadding: const EdgeInsets.only(left: 0, right: 0),
          trailing: item != null
              ? IconButton(
                  onPressed: () => itemSelected(null),
                  icon: const Icon(Icons.close),
                )
              : null,
        ),
        FractionallySizedBox(
          widthFactor: 1 / crossAxisCount,
          child: AspectRatio(
            aspectRatio: 1,
            child: item != null
                ? ShoppingItemWidget(
                    item: item!,
                    selected: true,
                    onPressed: (_) => _onPressed(context),
                    onLongPressed: (_) => _onLongPressed(context),
                  )
                : OutlinedButton(
                    onPressed: () => _onPressed(context),
                    child: const Icon(Icons.add),
                  ),
          ),
        ),
        if (item != null)
          Row(
            children: [
              Expanded(
                child: Text(AppLocalizations.of(context)!.optional),
              ),
              KitchenOwlSwitch(
                value: optional,
                onChanged: _setOptional,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final items =
        await Navigator.of(context).push<List<Item>>(MaterialPageRoute(
              builder: (context) => ItemSearchPage(
                multiple: false,
                title: string,
                selectedItems: item != null ? [item!] : const [],
              ),
            )) ??
            [];
    if (items.length == 1) {
      itemSelected(
        RecipeItem.fromItem(
          item: items[0],
          optional: optional,
        ),
      );
    }
  }

  Future<void> _onLongPressed(BuildContext context) async {
    final res = await Navigator.of(context).push<UpdateValue<RecipeItem>>(
      MaterialPageRoute(
        builder: (BuildContext context) => ItemPage(
          item: item!,
        ),
      ),
    );
    if (res != null &&
        res.data != null &&
        (res.state == UpdateEnum.deleted || res.state == UpdateEnum.updated)) {
      itemSelected(res.data!);
    }
  }

  void _setOptional(bool value) {
    itemSelected(item!.copyWith(optional: value));
  }
}
