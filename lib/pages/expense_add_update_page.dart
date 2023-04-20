import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/cubits/expense_add_update_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/currency_text_input_formatter.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/expense_add_update/paid_for_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AddUpdateExpensePage extends StatefulWidget {
  final Household household;
  final Expense? expense;

  AddUpdateExpensePage({
    super.key,
    this.expense,
    required this.household,
  }) : assert(household.member != null);

  @override
  _AddUpdateExpensePageState createState() => _AddUpdateExpensePageState();
}

class _AddUpdateExpensePageState extends State<AddUpdateExpensePage> {
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
      cubit = AddUpdateExpenseCubit(
        widget.household,
        Expense(
          amount: 0,
          paidById: BlocProvider.of<AuthCubit>(context).getUser()?.id ??
              widget.household.member![0].id,
          paidFor: widget.household.member!
              .map((e) => PaidForModel(userId: e.id, factor: 1))
              .toList(),
        ),
      );
    } else {
      cubit = AddUpdateExpenseCubit(widget.household, widget.expense!);
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
                tooltip: AppLocalizations.of(context)!.save,
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                        bloc: cubit,
                        buildWhen: (previous, current) =>
                            previous.image != current.image,
                        builder: (context, state) => ImageSelector(
                          image: state.image,
                          originalImage: cubit.expense.image,
                          setImage: cubit.setImage,
                        ),
                      ),
                      TextField(
                        controller: nameController,
                        onChanged: (s) => cubit.setName(s),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: BlocBuilder<AddUpdateExpenseCubit,
                                    AddUpdateExpenseState>(
                                  bloc: cubit,
                                  buildWhen: (previous, current) =>
                                      previous.date != current.date,
                                  builder: (context, state) => Text(
                                    DateFormat.yMMMMd()
                                        .add_jm()
                                        .format(state.date),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                child: const Icon(Icons.calendar_month_rounded),
                                onPressed: () async {
                                  final DateTime? date = await showDatePicker(
                                    context: context,
                                    initialDate: cubit.state.date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 400)),
                                  );
                                  if (date == null) return;

                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      cubit.state.date,
                                    ),
                                  );

                                  if (time == null) return;

                                  cubit.setDate(DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  ));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextField(
                        controller: amountController,
                        onTap: () => amountController.selection =
                            TextSelection.collapsed(
                          offset: amountController.text.length,
                        ),
                        onChanged: (s) {
                          cubit.setAmount(double.tryParse(s) ?? 0);
                          amountController.selection = TextSelection.collapsed(
                            offset: amountController.text.length,
                          );
                        },
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyTextInputFormater()],
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.expenseAmount,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
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
                      const SizedBox(height: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.category,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          BlocBuilder<AddUpdateExpenseCubit,
                              AddUpdateExpenseState>(
                            bloc: cubit,
                            buildWhen: (prev, curr) =>
                                prev.categories != curr.categories ||
                                prev.category != curr.category,
                            builder: (context, state) =>
                                DropdownButton<ExpenseCategory?>(
                              value: state.category,
                              isExpanded: true,
                              items: [
                                for (final e in (state.categories))
                                  DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                        bloc: cubit,
                        builder: (context, state) => Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isIncome
                                  ? AppLocalizations.of(context)!
                                      .expenseReceivedBy
                                  : AppLocalizations.of(context)!.expensePaidBy,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            DropdownButton<int>(
                              value: state.paidBy,
                              isExpanded: true,
                              onChanged: (id) {
                                if (id != null) cubit.setPaidById(id);
                              },
                              items: (widget.household.member ?? const [])
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
                      const SizedBox(height: 16),
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                        bloc: cubit,
                        buildWhen: (previous, current) =>
                            previous.isIncome != current.isIncome,
                        builder: (context, state) => Text(
                          state.isIncome
                              ? AppLocalizations.of(context)!.expenseReceivedFor
                              : AppLocalizations.of(context)!.expensePaidFor,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PaidForWidget(
                    user: widget.household.member![i],
                    cubit: cubit,
                  ),
                  childCount: widget.household.member?.length ?? 0,
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
