import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/cubits/expense_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/kitchenowl.dart';

class AddUpdateExpensePage extends StatefulWidget {
  final Expense expense;
  const AddUpdateExpensePage({Key key, this.expense = const Expense()})
      : super(key: key);

  @override
  _AddUpdateRecipePageState createState() => _AddUpdateRecipePageState();
}

class _AddUpdateRecipePageState extends State<AddUpdateExpensePage> {
  final TextEditingController nameController = TextEditingController();
  AddUpdateExpenseCubit cubit;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    isUpdate = widget.expense.id != null;
    if (isUpdate) {
      nameController.text = widget.expense.name;
    }
    cubit = AddUpdateExpenseCubit(widget.expense);
  }

  @override
  void dispose() {
    cubit.close();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(isUpdate
              ? AppLocalizations.of(context).recipeEdit
              : AppLocalizations.of(context).recipeNew),
          actions: [
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              IconButton(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () async {
                    await cubit.saveRecipe();
                    Navigator.of(context).pop(UpdateEnum.updated);
                  }),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 1600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: nameController,
                      onChanged: (s) => cubit.setName(s),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          FocusScope.of(context).nextFocus(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
