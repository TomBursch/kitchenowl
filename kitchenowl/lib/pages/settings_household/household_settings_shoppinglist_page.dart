import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/household_add_update/household_update_cubit.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/widgets/dismissible_card.dart';
import 'package:sliver_tools/sliver_tools.dart';

enum _ShoppinglistAction {
  rename,
  makeStandard,
  delete;
}

class HouseholdSettingsShoppinglistPage extends StatefulWidget {
  const HouseholdSettingsShoppinglistPage({super.key});

  @override
  State<HouseholdSettingsShoppinglistPage> createState() =>
      _HouseholdSettingsShoppinglistPageState();
}

class _HouseholdSettingsShoppinglistPageState
    extends State<HouseholdSettingsShoppinglistPage> {
  bool _isReordering = false;

  static Future<bool> confirmDeleteShoppingList(
      BuildContext context, ShoppingList shoppinglist) async {
    return await askForConfirmation(
        context: context,
        title: Text(
          AppLocalizations.of(context)!.shoppingListDelete,
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                AppLocalizations.of(context)!.shoppingListDeleteConfirmation(
                  shoppinglist.name,
                ),
              ),
              if (shoppinglist.items.length > 0) const SizedBox(height: 20),
              if (shoppinglist.items.length > 0)
                Text(AppLocalizations.of(context)!
                    .shoppingListContainsEntries(shoppinglist.items.length))
            ],
          ),
        ));
  }

  List<ShoppingList> _getSortedShoppingLists(List<ShoppingList> lists) {
    final sortedLists = List<ShoppingList>.from(lists);
    sortedLists.sort((a, b) {
      // Standard lists (index 0 in your current implementation) always come first
      if (a.isStandard && !b.isStandard) return -1;
      if (!a.isStandard && b.isStandard) return 1;
      // Among standard lists or non-standard lists, sort by order
      return a.order.compareTo(b.order);
    });
    return sortedLists;
  }

  List<ShoppingList> _getReorderableLists(List<ShoppingList> lists) {
    // Return only non-standard lists (everything except index 0)
    return lists.where((list) => !list.isStandard).toList();
  }

  List<ShoppingList> _getStandardLists(List<ShoppingList> lists) {
    // Return only standard lists (currently index 0)
    return lists.where((list) => list.isStandard).toList();
  }

  // 1. Update the _onReorder method with optimized logic:
  void _onReorder(List<ShoppingList> allLists, int oldIndex, int newIndex) {
    final reorderableLists = _getReorderableLists(allLists);
  
    if (newIndex > oldIndex) newIndex--;
    final item = reorderableLists.removeAt(oldIndex);
    reorderableLists.insert(newIndex, item);
  
    // Optimized order update using map
    final updatedLists = [
      ..._getStandardLists(allLists),
      for (var i = 0; i < reorderableLists.length; i++)
        reorderableLists[i].copyWith(order: i)
    ];
  
    BlocProvider.of<HouseholdUpdateCubit>(context)
        .reorderShoppingLists(updatedLists);
  }

  // 2. Enhance _saveOrder with better feedback:
  Future<void> _saveOrder() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderSaved),
          backgroundColor: Theme.of(context).primaryColor,
         behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context)!.shoppingLists),
            actions: [
              BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
                builder: (context, state) {
                  final reorderableLists = _getReorderableLists(state.shoppingLists);
                  
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Only show reorder button if there are multiple non-standard lists
                      // 3. Update the reorder button in build():
                      if (reorderableLists.length > 1)
                        IconButton(
                          icon: Icon(_isReordering ? Icons.check : Icons.sort),
                          tooltip: _isReordering 
                            ? AppLocalizations.of(context)!.saveOrder
                            : AppLocalizations.of(context)!.reorderLists,
                          onPressed: () {
                            setState(() => _isReordering = !_isReordering);
                            if (!_isReordering) _saveOrder();
      
                            // Show help when starting reorder
                            if (_isReordering) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.reorderHelpMessage),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: AppLocalizations.of(context)!.addShoppingList,
                        onPressed: _isReordering ? null : () async {
                          final res = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return TextDialog(
                                title: AppLocalizations.of(context)!.addShoppingList,
                                doneText: AppLocalizations.of(context)!.add,
                                hintText: AppLocalizations.of(context)!.name,
                                isInputValid: (s) => s.isNotEmpty,
                              );
                            },
                          );
                          if (res != null) {
                            BlocProvider.of<HouseholdUpdateCubit>(context)
                                .addShoppingList(res);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          SliverCrossAxisConstrained(
            maxCrossAxisExtent: 600,
            child: BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
              buildWhen: (prev, curr) =>
                  prev.shoppingLists != curr.shoppingLists ||
                  prev is LoadingHouseholdUpdateState,
              builder: (context, state) {
                if (state is LoadingHouseholdUpdateState) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final sortedLists = _getSortedShoppingLists(state.shoppingLists);
                final standardLists = _getStandardLists(sortedLists);
                final reorderableLists = _getReorderableLists(sortedLists);

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: sortedLists.length,
                    (context, i) {
                      final shoppingList = sortedLists[i];
                      final isStandard = shoppingList.isStandard || i == 0; // Fallback for current implementation
                      final isInReorderableSection = !isStandard && _isReordering;
                      
                      if (isInReorderableSection) {
                        // For reorderable items, we need to handle them differently
                        final reorderIndex = reorderableLists.indexOf(shoppingList);
                        return ReorderableDragStartListener(
                          key: ValueKey<int>(shoppingList.id ?? shoppingList.hashCode),
                          index: reorderIndex,
                          child: _buildShoppingListTile(
                            shoppingList, 
                            i, 
                            sortedLists, 
                            isReordering: true,
                            isStandard: false,
                          ),
                        );
                      }
                      
                      return _buildShoppingListTile(
                        shoppingList, 
                        i, 
                        sortedLists,
                        isStandard: isStandard,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Add ReorderableListView for non-standard lists when in reorder mode
          if (_isReordering)
            SliverCrossAxisConstrained(
              maxCrossAxisExtent: 600,
              child: BlocBuilder<HouseholdUpdateCubit, HouseholdUpdateState>(
                builder: (context, state) {
                  final reorderableLists = _getReorderableLists(state.shoppingLists);
                  
                  if (reorderableLists.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  
                  return SliverToBoxAdapter(
                    // 4. Enhance the ReorderableListView builder:
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reorderableLists.length,
                      onReorder: (oldIndex, newIndex) => 
                        _onReorder(state.shoppingLists, oldIndex, newIndex),
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 8,
                        shadowColor: Theme.of(context).colorScheme.shadow,
                        borderRadius: BorderRadius.circular(8),
                        child: child,
                      ),
                      itemBuilder: (context, index) {
                        final shoppingList = reorderableLists[index];
                          return ReorderableDragStartListener(
                            key: ValueKey<int>(shoppingList.id ?? shoppingList.hashCode),
                            index: index,
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              elevation: 4,
                              child: ListTile(
                                leading: const Icon(Icons.drag_handle),
                                title: Text(shoppingList.name),
                                trailing: const Icon(Icons.drag_indicator),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShoppingListTile(
    ShoppingList shoppingList, 
    int index, 
    List<ShoppingList> allLists, {
    bool isReordering = false,
    bool isStandard = false,
  }) {
    if (_isReordering && !isStandard) {
      // Don't render non-standard items in the main list during reordering
      // They'll be handled by the ReorderableListView
      return const SizedBox.shrink();
    }

    return DismissibleCard(
      key: ValueKey<String>(shoppingList.name),
      isDismissable: !isStandard && !_isReordering,
      confirmDismiss: (direction) async =>
          await confirmDeleteShoppingList(context, shoppingList),
      onDismissed: (direction) {
        BlocProvider.of<HouseholdUpdateCubit>(context)
            .deleteShoppingList(shoppingList);
      },
      title: Row(
        children: [
          if (isReordering && !isStandard)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.drag_handle),
            ),
          Expanded(child: Text(shoppingList.name)),
          if (isStandard)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.standardShoppingList,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: isStandard 
        ? Text('(${AppLocalizations.of(context)!.defaultWord})')
        : null,
      onTap: _isReordering ? null : () async {
        _handleAction(
          context,
          allLists,
          index,
          await showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (context) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        shoppingList.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.edit_rounded),
                          label: Text(AppLocalizations.of(context)!.rename),
                          onPressed: () => Navigator.of(context)
                              .pop(_ShoppinglistAction.rename),
                        ),
                        if (!isStandard) ...[
                          ActionChip(
                            avatar: const Icon(Icons.star),
                            label: Text('Make Standard List'),
                            onPressed: () => Navigator.of(context)
                                .pop(_ShoppinglistAction.makeStandard),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.delete_rounded),
                            label: Text(AppLocalizations.of(context)!.delete),
                            onPressed: () => Navigator.of(context)
                                .pop(_ShoppinglistAction.delete),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    List<ShoppingList> shoppingLists,
    int shoppingListIndex,
    _ShoppinglistAction? action,
  ) async {
    if (action == null) return;
    
    final shoppingList = shoppingLists[shoppingListIndex];
    
    switch (action) {
      case _ShoppinglistAction.rename:
        final res = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return TextDialog(
              title: AppLocalizations.of(context)!.shoppingListEdit,
              doneText: AppLocalizations.of(context)!.rename,
              hintText: AppLocalizations.of(context)!.name,
              initialText: shoppingList.name,
              isInputValid: (s) =>
                  s.trim().isNotEmpty && s != shoppingList.name,
            );
          },
        );

        if (res != null) {
          BlocProvider.of<HouseholdUpdateCubit>(context).updateShoppingList(
            shoppingList.copyWith(name: res),
          );
        }
        break;
        
      case _ShoppinglistAction.makeStandard:
        // This would need to be implemented in your cubit
        BlocProvider.of<HouseholdUpdateCubit>(context)
            .makeStandardList(shoppingList);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${shoppingList.name} is now the standard list'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
        
      case _ShoppinglistAction.delete:
        if (await confirmDeleteShoppingList(context, shoppingList)) {
          BlocProvider.of<HouseholdUpdateCubit>(context)
              .deleteShoppingList(shoppingList);
        }
        break;
    }
  }
}
