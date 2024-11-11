import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/household_cubit.dart';
import 'package:kitchenowl/cubits/item_edit_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/build_context_extension.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/update_value.dart';
import 'package:kitchenowl/widgets/item_popup_menu_button.dart';
import 'package:kitchenowl/widgets/item_wrap_menu.dart';
import 'package:kitchenowl/widgets/recipe_item.dart';

class ItemPage<T extends Item> extends StatefulWidget {
  final T item;
  final ShoppingList? shoppingList;
  final List<Category> categories;
  final bool advancedView;

  const ItemPage({
    super.key,
    required this.item,
    this.shoppingList,
    this.categories = const [],
    this.advancedView = false,
  });

  @override
  _ItemPageState createState() => _ItemPageState<T>();
}

class _ItemPageState<T extends Item> extends State<ItemPage<T>> {
  final TextEditingController descController = TextEditingController();

  late ItemEditCubit<T> cubit;

  @override
  void initState() {
    super.initState();
    if (widget.item is ItemWithDescription) {
      descController.text = (widget.item as ItemWithDescription).description;
    }
    cubit = ItemEditCubit<T>(
      household: context.read<HouseholdCubit>().state.household,
      item: widget.item,
      shoppingList: widget.shoppingList,
    );
  }

  @override
  void dispose() {
    cubit.close();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemEditCubit, ItemEditState>(
      bloc: cubit,
      buildWhen: (prev, curr) =>
          prev.hasChanged(widget.item) != curr.hasChanged(widget.item),
      builder: (context, state) => PopScope(
        canPop: !state.hasChanged(widget.item),
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && state.hasChanged(widget.item)) {
            await cubit.saveItem();
            if (mounted) {
              Navigator.of(context)
                  .pop(UpdateValue<T>(UpdateEnum.updated, cubit.item));
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: BlocBuilder<ItemEditCubit, ItemEditState>(
              bloc: cubit,
              buildWhen: (prev, curr) => prev.name != curr.name,
              builder: (context, state) => Text(state.name),
            ),
            actions: [
              if (!App.isOffline)
                ItemPopupMenuButton(
                  item: cubit.item,
                  household: context.read<HouseholdCubit>().state.household,
                  setIcon: cubit.setIcon,
                  setName: cubit.setName,
                  mergeItem: cubit.mergeItem,
                  deleteItem: () async {
                    await cubit.deleteItem();
                    if (!mounted) return;
                    Navigator.of(context)
                        .pop(const UpdateValue<Item>(UpdateEnum.deleted));
                  },
                ),
            ],
          ),
          body: Scrollbar(
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                slivers: [
                  if (widget.item is ItemWithDescription)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          autofocus: true,
                          controller: descController,
                          onChanged: (s) => cubit.setDescription(s),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                            ),
                            labelText:
                                AppLocalizations.of(context)!.description,
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
                  if (widget.item is! RecipeItem)
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: (widget.item is ItemWithDescription) ? 0 : 16,
                        bottom: (widget.advancedView) ? 8 : 16,
                        left: 16,
                        right: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Text(
                              AppLocalizations.of(context)!.category,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      BlocBuilder<ItemEditCubit, ItemEditState>(
                                    bloc: cubit,
                                    buildWhen: (prev, curr) =>
                                        prev.category != curr.category,
                                    builder: (context, state) =>
                                        DropdownButton<Category?>(
                                      value: state.category,
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem(
                                          value: null,
                                          child: Text(
                                            AppLocalizations.of(context)!.none,
                                          ),
                                        ),
                                        for (final e in widget.categories)
                                          DropdownMenuItem(
                                            value: e,
                                            child: Text(e.name),
                                          ),
                                      ],
                                      onChanged: !App.isOffline
                                          ? cubit.setCategory
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.item is ShoppinglistItem)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  AppLocalizations.of(context)!.addedBy(context
                                          .read<HouseholdCubit>()
                                          .state
                                          .household
                                          .member
                                          ?.firstWhereOrNull(
                                            (e) =>
                                                e.id ==
                                                (widget.item
                                                        as ShoppinglistItem)
                                                    .createdById,
                                          )
                                          ?.name ??
                                      AppLocalizations.of(context)!.other),
                                ),
                                trailing: (widget.item as ShoppinglistItem)
                                            .createdAt !=
                                        null
                                    ? Text(
                                        DateFormat.yMMMEd().add_jm().format(
                                              (widget.item as ShoppinglistItem)
                                                  .createdAt!,
                                            ),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.advancedView)
                    BlocBuilder<ItemEditCubit, ItemEditState>(
                      bloc: cubit,
                      builder: (context, state) => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (!App.isOffline)
                              ItemWrapMenu(
                                item: cubit.item,
                                household: context
                                    .read<HouseholdCubit>()
                                    .state
                                    .household,
                                setIcon: cubit.setIcon,
                                setName: cubit.setName,
                                mergeItem: cubit.mergeItem,
                                deleteItem: () async {
                                  await cubit.deleteItem();
                                  if (!mounted) return;
                                  Navigator.of(context).pop(
                                      const UpdateValue<Item>(
                                          UpdateEnum.deleted));
                                },
                              ),
                            const Divider(height: 32),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                AppLocalizations.of(context)!.about,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text(AppLocalizations.of(context)!.ordering),
                              trailing: Text(widget.item.ordering.toString()),
                            ),
                            if (state.icon != null)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(AppLocalizations.of(context)!.icon),
                                trailing: Text(state.icon ?? ""),
                              ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  AppLocalizations.of(context)!.defaultWord),
                              trailing: Text(widget.item.isDefault.toString()),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                  AppLocalizations.of(context)!.defaultKey),
                              trailing: Text(widget.item.defaultKey ?? ""),
                            ),
                            const Divider(),
                          ]),
                        ),
                      ),
                    ),
                  if (widget.item is! RecipeItem &&
                      context.readOrNull<HouseholdCubit>() != null)
                    BlocProvider.value(
                      value: context.read<HouseholdCubit>(),
                      child: BlocBuilder<ItemEditCubit, ItemEditState>(
                        bloc: cubit,
                        builder: (context, state) {
                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  if (i == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '${AppLocalizations.of(context)!.usedIn}:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    );
                                  }
                                  i = i - 1;

                                  return RecipeItemWidget(
                                    recipe: state.recipes[i],
                                    onUpdated: cubit.refresh,
                                    description: state.recipes[i].isPlanned &&
                                            state.recipes[i].items.isNotEmpty &&
                                            state.recipes[i].items.first
                                                .description.isNotEmpty
                                        ? Text(
                                            "${state.recipes[i].items.first.description}${state.recipes[i].items.first.optional ? " (${AppLocalizations.of(context)!.optional})" : ""}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          )
                                        : state.recipes[i].items.first.optional
                                            ? Text(
                                                AppLocalizations.of(context)!
                                                    .optional,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              )
                                            : null,
                                  );
                                },
                                childCount: state.recipes.isEmpty
                                    ? 0
                                    : state.recipes.length + 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child:
                        SizedBox(height: MediaQuery.paddingOf(context).bottom),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
