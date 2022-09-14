import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/expense_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/currency_text_input_formatter.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:collection/collection.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
      amountController.text = widget.expense!.amount.abs().toStringAsFixed(2);
    }
    if (widget.expense == null) {
      amountController.text = 0.toStringAsFixed(2);
      cubit = AddUpdateExpenseCubit(Expense(
        amount: 0,
        paidById: BlocProvider.of<AuthCubit>(context).getUser()?.id ??
            widget.users[0].id,
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
    final bool mobileLayout = getValueForScreenType<bool>(
      context: context,
      mobile: true,
      desktop: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdate
            ? AppLocalizations.of(context)!.expenseEdit
            : AppLocalizations.of(context)!.expenseAdd),
        actions: [
          if (mobileLayout)
            BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
              bloc: cubit,
              builder: (context, state) => LoadingIconButton(
                icon: const Icon(Icons.save_rounded),
                onPressed: state.isValid()
                    ? () async {
                        await cubit.saveExpense();
                        if (!mounted) return;
                        Navigator.of(context).pop(UpdateEnum.updated);
                      }
                    : null,
              ),
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
                        inputFormatters: [CurrencyTextInputFormater()],
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.expenseAmount,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BlocBuilder<AddUpdateExpenseCubit,
                          AddUpdateExpenseState>(
                        bloc: cubit,
                        buildWhen: (prev, curr) =>
                            prev.isIncome != curr.isIncome,
                        builder: (context, state) => Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: !state.isIncome
                                      ? MaterialStateProperty.all(
                                          Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                  foregroundColor: !state.isIncome
                                      ? MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        )
                                      : null,
                                  shape: MaterialStateProperty.all(
                                    const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () => cubit.setIncome(false),
                                child: Text(
                                  AppLocalizations.of(context)!.expense,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: state.isIncome
                                      ? MaterialStateProperty.all(
                                          Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                  foregroundColor: state.isIncome
                                      ? MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        )
                                      : null,
                                  shape: MaterialStateProperty.all(
                                    const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                onPressed: () => cubit.setIncome(true),
                                child: Text(
                                  AppLocalizations.of(context)!.income,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.category,
                            style: Theme.of(context).textTheme.caption,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: BlocBuilder<AddUpdateExpenseCubit,
                                    AddUpdateExpenseState>(
                                  bloc: cubit,
                                  buildWhen: (prev, curr) =>
                                      prev.categories != curr.categories ||
                                      prev.category != curr.category,
                                  builder: (context, state) =>
                                      DropdownButton<String?>(
                                    value: state.category,
                                    isExpanded: true,
                                    items: [
                                      for (final e in (state.categories))
                                        DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          AppLocalizations.of(context)!.none,
                                        ),
                                      ),
                                    ],
                                    onChanged: cubit.setCategory,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final res = await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return TextDialog(
                                        title: AppLocalizations.of(context)!
                                            .addCategory,
                                        doneText:
                                            AppLocalizations.of(context)!.add,
                                        hintText:
                                            AppLocalizations.of(context)!.name,
                                      );
                                    },
                                  );
                                  if (res != null && res.isNotEmpty) {
                                    cubit.setCategory(res);
                                  }
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
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
                                      value: user.id,
                                      child: Text(user.name),
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
                                  (e) => e.userId == widget.users[i].id,
                                )
                                ?.factor
                                .toString()) ??
                            "",
                      );

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
                                      .firstWhereOrNull(
                                        (e) => e.userId == widget.users[i].id,
                                      )
                                      ?.factor ??
                                  0) /
                              state.paidFor.fold(0, (p, v) => p + v.factor)),
                        )),
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
                              widget.users[i],
                              int.tryParse(t) ?? 1,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
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
                    child: LoadingElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.redAccent,
                        ),
                        foregroundColor: MaterialStateProperty.all<Color>(
                          Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        await cubit.deleteExpense();
                        if (!mounted) return;
                        Navigator.of(context).pop(UpdateEnum.deleted);
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ),
              if (!mobileLayout)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, isUpdate ? 0 : 16, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: BlocBuilder<AddUpdateExpenseCubit,
                        AddUpdateExpenseState>(
                      bloc: cubit,
                      builder: (context, state) => LoadingElevatedButton(
                        onPressed: state.isValid()
                            ? (() async {
                                await cubit.saveExpense();
                                if (!mounted) return;
                                Navigator.of(context).pop(UpdateEnum.updated);
                              })
                            : null,
                        child: Text(
                          isUpdate
                              ? AppLocalizations.of(context)!.save
                              : AppLocalizations.of(context)!.expenseAdd,
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
