import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
// Import the new transaction file
import 'package:kitchenowl/services/transactions/mass_import.dart';
import 'package:kitchenowl/kitchenowl.dart';

class MassImportPage extends StatefulWidget {
  final Household household;

  const MassImportPage({
    super.key,
    required this.household,
  });

  @override
  State<MassImportPage> createState() => _MassImportPageState();
}

class _MassImportPageState extends State<MassImportPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processImport(BuildContext context) async {
    final text = _controller.text;

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)?.massImportEnterText ??
                "Please enter some text to import.")),
      );
      return;
    }

    // 1. Parse all items
    List<ShoppinglistItem> itemsToImport = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.split(RegExp(r'[|;,]'));
      String name = parts[0].trim();
      String description = '';

      if (parts.length > 1) {
        description = parts.sublist(1).join(" ").trim();
      }

      if (name.isNotEmpty) {
        itemsToImport.add(ShoppinglistItem(
          name: name,
          description: description,
          createdAt: DateTime.now(),
        ));
      }
    }

    if (itemsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.massImportNoValidItems ?? "No valid items found to import.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionHandler = TransactionHandler.getInstance();

      // Resolve items using the search functionality
      List<ShoppinglistItem> resolvedItems = [];
      for (var item in itemsToImport) {
        try {
          final results = await transactionHandler.runTransaction(
            TransactionShoppingListSearchItem(
              household: widget.household,
              query: item.name,
            ),
          );

          final match = results.firstWhereOrNull(
                  (e) => e.name.toLowerCase() == item.name.toLowerCase());

          if (match != null) {
            resolvedItems.add(ShoppinglistItem.fromItem(
              item: match,
              description: item.description,
            ));
          } else {
            resolvedItems.add(item);
          }
        } catch (e) {
          // If search fails, just add the item as is
          resolvedItems.add(item);
        }
      }

      // 2. Fetch available shopping lists for this household
      final shoppingLists = await transactionHandler.runTransaction(
        TransactionShoppingListGet(household: widget.household),
        forceOffline: true, // Usually fine to use cached lists for selection
      );

      ShoppingList? targetList = widget.household.defaultShoppingList;

      if (shoppingLists.length > 1) {
        if (!mounted) return;

        targetList = await showDialog<ShoppingList>(
          context: context,
          builder: (context) => SelectDialog(
            title: AppLocalizations.of(context)!
                .addNumberIngredients(resolvedItems.length),
            cancelText: AppLocalizations.of(context)!.cancel,
            options: shoppingLists
                .map(
                  (e) => SelectDialogOption(
                e,
                e.name,
              ),
            )
                .toList(),
          ),
        );
      } else if (shoppingLists.isNotEmpty) {
        targetList = shoppingLists.first;
      }

      if (targetList != null) {
        // 3. Perform the add transaction using the imported class
        await transactionHandler.runTransaction(
          TransactionShoppingListAddItems(
            household: widget.household,
            shoppinglist: targetList,
            items: resolvedItems,
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.massImportSuccess(resolvedItems.length))),
          );
          _controller.clear();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.massImportError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.massImportTitle ?? "Mass Import"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)?.massImportDescription ?? "Enter items one per line.\nSeparate name and description with '|' or ';' or ','",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: AppLocalizations.of(context)?.massImportHint ?? "Milk\nBread | For sandwiches\nEggs; 12 pack",
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _processImport(context),
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.playlist_add_rounded),
                label: Text(AppLocalizations.of(context)?.massImportButton ?? "Import Items"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
