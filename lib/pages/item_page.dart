import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/item_edit_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';

class ItemPage extends StatefulWidget {
  final Item item;

  const ItemPage({Key key, this.item}) : super(key: key);

  @override
  _ItemPageState createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final TextEditingController descController = TextEditingController();

  ItemEditCubit cubit;

  @override
  void initState() {
    super.initState();
    if (widget.item is ShoppinglistItem) {
      descController.text = (widget.item as ShoppinglistItem).description;
    }
    cubit = ItemEditCubit(item: widget.item);
  }

  @override
  void dispose() {
    cubit.close();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (cubit.hasChanged()) {
          await cubit.saveItem();
          Navigator.of(context).pop(UpdateEnum.updated);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item.name),
          actions: [
            if (!App.isOffline(context))
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                AppLocalizations.of(context).userDelete,
                              ),
                              content: Text(AppLocalizations.of(context)
                                  .itemDeleteConfirmation(widget.item.name)),
                              actions: <Widget>[
                                TextButton(
                                  child:
                                      Text(AppLocalizations.of(context).cancel),
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Theme.of(context).disabledColor,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                ),
                                TextButton(
                                  child:
                                      Text(AppLocalizations.of(context).delete),
                                  style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                      Colors.red,
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                ),
                              ],
                            );
                          }) ??
                      false;
                  if (confirmed && await cubit.deleteItem()) {
                    Navigator.of(context).pop(UpdateEnum.deleted);
                  }
                },
                icon: const Icon(Icons.delete),
              )
          ],
        ),
        body: Scrollbar(
          child: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              slivers: [
                if (widget.item is ShoppinglistItem)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        autofocus: true,
                        controller: descController,
                        onChanged: (s) => cubit.setDescription(s),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: AppLocalizations.of(context).description,
                          // suffix: IconButton(
                          //   onPressed: () {
                          //     if (descController.text.isNotEmpty) {
                          //       cubit.setDescription('');
                          //       descController.clear();
                          //     }
                          //     FocusScope.of(context).unfocus();
                          //   },
                          //   icon: Icon(
                          //     Icons.close,
                          //     color: Colors.grey,
                          //   ),
                          // ),
                        ),
                      ),
                    ),
                  ),
                BlocBuilder<ItemEditCubit, ItemEditState>(
                  bloc: cubit,
                  builder: (context, state) {
                    return SliverPadding(
                      padding: EdgeInsets.only(
                        top: (widget.item is ShoppinglistItem) ? 0 : 16,
                        bottom: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            child: RecipeItemWidget(
                              recipe: state.recipes[i],
                              onUpdated: cubit.refresh,
                            ),
                          ),
                          childCount: state.recipes.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
