import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_search_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ItemSearchPage extends StatefulWidget {
  final Household household;
  final bool multiple;
  final List<Item> selectedItems;
  final String? title;

  const ItemSearchPage({
    super.key,
    required this.household,
    this.multiple = true,
    this.title,
    this.selectedItems = const [],
  });

  @override
  _ItemSearchPageState createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  final TextEditingController searchController = TextEditingController();
  late ItemSearchCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ItemSearchCubit(widget.household, widget.selectedItems);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appbar = AppBar(
      title: Text(widget.title ?? AppLocalizations.of(context)!.itemsAdd),
      leading: BackButton(
        onPressed: () => Navigator.of(context).pop(cubit.state.selectedItems),
      ),
      flexibleSpace: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: BlocListener<ItemSearchCubit, ItemSearchState>(
              bloc: cubit,
              listener: (context, state) {
                if (state.query.isEmpty && searchController.text.isNotEmpty) {
                  searchController.clear();
                }
              },
              child: SearchTextField(
                controller: searchController,
                onSearch: cubit.search,
                autofocus: true,
                alwaysExpanded: true,
                textInputAction: TextInputAction.done,
                onSubmitted: () {
                  if (cubit.state.selectedItems
                      .contains(cubit.state.searchResults.first)) return;
                  if (!widget.multiple) {
                    final item = cubit.state.searchResults.first;
                    Navigator.of(context).pop([item]);
                  } else {
                    cubit.itemSelected(cubit.state.searchResults.first);
                  }
                },
                hintText: AppLocalizations.of(context)!.searchHint,
                labelText: const Nullable.empty(),
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(cubit.state.selectedItems);
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appbar.preferredSize.height + 56),
          child: appbar,
        ),
        body: BlocBuilder<ItemSearchCubit, ItemSearchState>(
          bloc: cubit,
          builder: (context, state) => CustomScrollView(
            slivers: [
              SliverItemGridList(
                items: state.searchResults,
                selected: (item) => state.selectedItems.contains(item),
                onLongPressed: const Nullable<void Function(Item)>.empty(),
                onPressed: Nullable((Item item) {
                  if (!widget.multiple) {
                    Navigator.of(context).pop([item]);
                  } else {
                    cubit.itemSelected(item);
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
