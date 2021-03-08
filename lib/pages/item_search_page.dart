import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_search_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/home_page/shopping_item.dart';

class ItemSearchPage extends StatefulWidget {
  final bool multiple;
  final List<Item> selectedItems;
  final String title;

  const ItemSearchPage({
    Key key,
    this.multiple = true,
    this.title,
    this.selectedItems = const [],
  }) : super(key: key);

  @override
  _ItemSearchPageState createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  final TextEditingController searchController = TextEditingController();
  ItemSearchCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ItemSearchCubit(widget.selectedItems);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appbar = AppBar(
      title: Text(widget.title ?? AppLocalizations.of(context).itemsAdd),
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
              cubit: cubit,
              listener: (context, state) {
                if (state.query.isEmpty && searchController.text.isNotEmpty) {
                  searchController.clear();
                }
              },
              child: TextField(
                controller: searchController,
                onChanged: cubit.search,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {},
                onSubmitted: (text) {
                  if (cubit.state.selectedItems
                      .map((e) => e.name)
                      .contains(cubit.state.searchResults.first.name)) return;
                  if (!widget.multiple) {
                    final item = cubit.state.searchResults.first;
                    Navigator.of(context).pop([item]);
                  } else {
                    cubit.itemSelected(0);
                  }
                },
                decoration: InputDecoration(
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  filled: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  suffix: IconButton(
                    onPressed: () {
                      if (searchController.text.isNotEmpty) {
                        cubit.search('');
                      }
                      FocusScope.of(context).unfocus();
                    },
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey,
                    ),
                  ),
                  hintText: AppLocalizations.of(context).searchHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appbar.preferredSize.height + 56),
        child: appbar,
      ),
      body: BlocBuilder<ItemSearchCubit, ItemSearchState>(
        cubit: cubit,
        builder: (context, state) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: state.searchResults.length,
          itemBuilder: (context, i) => ShoppingItemWidget(
            item: state.searchResults[i],
            selected: state.selectedItems.map((e) => e.name).contains(state
                .searchResults[i]
                .name), //#TODO map shouldn't be necessary (Bug in equatable?)
            onPressed: (item) {
              if (!widget.multiple)
                Navigator.of(context).pop([item]);
              else
                cubit.itemSelected(i);
            },
          ),
        ),
      ),
    );
  }
}
