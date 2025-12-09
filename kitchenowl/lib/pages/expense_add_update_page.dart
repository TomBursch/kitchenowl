import 'package:collection/collection.dart';
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
  final Map<String, ExpenseCategory?>? suggestedNames;

  AddUpdateExpensePage({
    super.key,
    this.expense,
    required this.household,
    this.suggestedNames,
  }) : assert(household.member != null);

  @override
  _AddUpdateExpensePageState createState() => _AddUpdateExpensePageState();
}

class _AddUpdateExpensePageState extends State<AddUpdateExpensePage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  late AddUpdateExpenseCubit cubit;
  bool isUpdate = false;

  @override
  void initState() {
    super.initState();
    isUpdate = widget.expense?.id != null;
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
      amountController.text = widget.expense!.amount.abs().toStringAsFixed(2);
      descriptionController.text = widget.expense!.description ?? "";
      cubit = AddUpdateExpenseCubit(widget.household, widget.expense!);
    }
  }

  @override
  void dispose() {
    cubit.close();
    amountController.dispose();
    descriptionController.dispose();
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
                      Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (widget.suggestedNames == null ||
                              textEditingValue.text.isEmpty) {
                            return const Iterable.empty();
                          }

                          return widget.suggestedNames!.keys
                              .where(
                                (e) => e.toLowerCase().startsWith(
                                    textEditingValue.text.toLowerCase()),
                              )
                              .toSet()
                              .take(5);
                        },
                        initialValue:
                            TextEditingValue(text: widget.expense?.name ?? ""),
                        onSelected: (s) {
                          cubit.setName(s);
                          ExpenseCategory? category = (widget.suggestedNames
                                      ?.containsKey(s) ??
                                  false)
                              ? cubit.state.categories.firstWhereOrNull(
                                  (e) => widget.suggestedNames![s]?.id == e.id)
                              : null;
                          if (category != null) cubit.setCategory(category);
                        },
                        fieldViewBuilder: (context, textEditingController,
                                focusNode, onFieldSubmitted) =>
                            TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onChanged: cubit.setName,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: cubit.setDescription,
                        textCapitalization: TextCapitalization.sentences,
                        controller: descriptionController,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          labelText: AppLocalizations.of(context)!.description,
                          hintText:
                              AppLocalizations.of(context)!.writeMarkdownHere,
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
                                      ? WidgetStateProperty.all(
                                          Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                  foregroundColor: !state.isIncome
                                      ? WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        )
                                      : null,
                                  shape: WidgetStateProperty.all(
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
                                      ? WidgetStateProperty.all(
                                          Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                  foregroundColor: state.isIncome
                                      ? WidgetStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        )
                                      : null,
                                  shape: WidgetStateProperty.all(
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
                      const SizedBox(height: 4),
                      BlocBuilder<AddUpdateExpenseCubit, AddUpdateExpenseState>(
                        bloc: cubit,
                        buildWhen: (previous, current) =>
                            previous.excludeFromStatistics !=
                            current.excludeFromStatistics,
                        builder: (context, state) => CheckboxListTile(
                          value: state.excludeFromStatistics,
                          onChanged: cubit.setExcludeFromStatistics,
                          title: Text(AppLocalizations.of(context)!
                              .excludeFromStatistics),
                          secondary: const Icon(Icons.pie_chart_rounded),
                          contentPadding: EdgeInsets.zero,
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
                    locale: widget.household.language,
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
                        backgroundColor: WidgetStateProperty.all<Color>(
                          Colors.redAccent,
                        ),
                        foregroundColor: WidgetStateProperty.all<Color>(
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
                child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
