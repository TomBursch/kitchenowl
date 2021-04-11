import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/item_search_cubit.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/search_text_field.dart';
import 'package:kitchenowl/widgets/shopping_item.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
    final int crossAxisCount = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 6,
      desktop: 9,
    );
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
                textInputAction: TextInputAction.done,
                onSubmitted: () {
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
                  filled: true,
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
                    padding: EdgeInsets.zero,
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
        bloc: cubit,
        builder: (context, state) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
