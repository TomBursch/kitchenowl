import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/currency_text_input_formatter.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/widgets/checkbox_list_tile.dart';
import 'package:collection/collection.dart';

class AddUpdateExpensePage extends StatefulWidget {
  final Expense? expense;
  final List<User> users;

  const AddUpdateExpensePage({Key? key, this.expense, required this.users})
      : super(key: key);

  @override
  _AddUpdateRecipePageState createState() => _AddUpdateRecipePageState();
}

class _AddUpdateRecipePageState extends State<AddUpdateExpensePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  late AddUpdateExpenseCubit cubit;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    isUpdate = widget.expense?.id != null;
    if (isUpdate) {
      nameController.text = widget.expense!.name;
      amountController.text = widget.expense!.amount.toStringAsFixed(2);
    }
    if (widget.expense == null) {
      amountController.text = 0.toStringAsFixed(2);
      cubit = AddUpdateExpenseCubit(Expense(
        amount: 0,
        paidById: widget.users[0].id,
        paidFor: widget.users
            .map((e) => PaidForModel(userId: e.id, factor: 1))
            .toList(),
      ));
    } else {
      cubit = AddUpdateExpenseCubit(widget.expense!);
    }
  }

  @override
  void dispose() {
    cubit.close();
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(isUpdate
              ? AppLocalizations.of(context)!.expenseEdit
              : AppLocalizations.of(context)!.expenseAdd),
          actions: [
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                bloc: cubit,
                builder: (context, state) => IconButton(
                    icon: const Icon(Icons.save_rounded),
                    onPressed: state.isValid()
                        ? () async {
                            await cubit.saveExpense();
                            Navigator.of(context).pop(UpdateEnum.updated);
                          }
                        : null),
              ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(width: 1600),
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: nameController,
                          onChanged: (s) => cubit.setName(s),
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.name,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: amountController,
                          onChanged: (s) =>
                              cubit.setAmount(double.tryParse(s) ?? 0),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          onEditingComplete: () =>
                              FocusScope.of(context).nextFocus(),
                          inputFormatters: [CurrencyTextInputFormater()],
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.expenseAmount,
                          ),
                        ),
                      ),
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                        bloc: cubit,
                        builder: (context, state) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.expensePaidBy,
                                style: Theme.of(context).textTheme.caption,
                              ),
                              DropdownButton<int>(
                                value: state.paidBy,
                                isExpanded: true,
                                onChanged: (id) {
                                  if (id != null) cubit.setPaidById(id);
                                },
                                items: widget.users
                                    .map(
                                      (user) => DropdownMenuItem<int>(
                                        child: Text(user.name),
                                        value: user.id,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          AppLocalizations.of(context)!.expensePaidFor,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                    ],
                  ),
                ),
                BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                  bloc: cubit,
                  builder: (context, state) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final controller = TextEditingController(
                            text: (cubit.state.paidFor
                                    .firstWhereOrNull(
                                        (e) => e.userId == widget.users[i].id)
                                    ?.factor
                                    .toString()) ??
                                "");
                        return CustomCheckboxListTile(
                          title: Text(widget.users[i].name),
                          value: cubit.containsUser(widget.users[i]),
                          onChanged: (v) {
                            if (v != null) {
                              if (v) {
                                cubit.addUser(widget.users[i]);
                              } else {
                                cubit.removeUser(widget.users[i]);
                              }
                            }
                          },
                          subtitle: Text(NumberFormat.simpleCurrency().format(
                              (state.amount *
                                  (cubit.state.paidFor
                                          .firstWhereOrNull((e) =>
                                              e.userId == widget.users[i].id)
                                          ?.factor ??
                                      0) /
                                  state.paidFor
                                      .fold(0, (p, v) => p + v.factor)))),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              maxWidth: 100,
                            ),
                            child: TextField(
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              controller: controller,
                              onTap: () {
                                cubit.addUser(widget.users[i]);
                                controller.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: controller.text.length,
                                );
                              },
                              onChanged: (t) => cubit.setFactor(
                                  widget.users[i], int.tryParse(t) ?? 1),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onEditingComplete: () =>
                                  FocusScope.of(context).nextFocus(),
                            ),
                          ),
                        );
                      },
                      childCount: widget.users.length,
                    ),
                  ),
                ),
                if (isUpdate)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.redAccent),
                        ),
                        onPressed: () async {
                          await cubit.deleteExpense();
                          Navigator.of(context).pop(UpdateEnum.deleted);
                        },
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                    ),
                  ),
                if (kIsWeb || (!(Platform.isAndroid || Platform.isIOS)))
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, isUpdate ? 0 : 16, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: BlocBuilder<AddUpdateExpenseCubit,
                              AddUpdateExpenseState>(
                          bloc: cubit,
                          builder: (context, state) => ElevatedButton(
                                onPressed: state.isValid()
                                    ? (() async {
                                        await cubit.saveExpense();
                                        Navigator.of(context)
                                            .pop(UpdateEnum.updated);
                                      })
                                    : null,
                                child: Text(
                                  isUpdate
                                      ? AppLocalizations.of(context)!.save
                                      : AppLocalizations.of(context)!
                                          .expenseAdd,
                                ),
                              )),
                    ),
                  )
              ],
            ),
          ),
        ));
  }
}
