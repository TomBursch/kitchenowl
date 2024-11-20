import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_cubit.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/pages/expense_add_update_page.dart';
import 'package:kitchenowl/kitchenowl.dart';

class ExpensePage extends StatefulWidget {
  final Household household;
  final Expense expense;

  const ExpensePage({
    super.key,
    required this.expense,
    required this.household,
  });

  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  late ExpenseCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ExpenseCubit(widget.expense, widget.household);
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(cubit.state.updateState);
      },
      child: BlocBuilder<ExpenseCubit, ExpenseCubitState>(
        bloc: cubit,
        builder: (conext, state) => Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints.expand(width: 1600),
              child: CustomScrollView(
                slivers: [
                  SliverImageAppBar(
                    title: state.expense.name,
                    imageUrl: state.expense.image,
                    imageHash: state.expense.imageHash,
                    popValue: () => cubit.state.updateState,
                    actions: (isCollapsed) => [
                      if (!App.isOffline)
                        LoadingIconButton(
                          tooltip: AppLocalizations.of(context)!.expenseEdit,
                          variant: state.expense.image == null ||
                                  state.expense.image!.isEmpty ||
                                  isCollapsed
                              ? LoadingIconButtonVariant.standard
                              : LoadingIconButtonVariant.filledTonal,
                          onPressed: () async {
                            final res = await Navigator.of(context)
                                .push<UpdateEnum>(MaterialPageRoute(
                              builder: (context) => AddUpdateExpensePage(
                                household: state.household,
                                expense: state.expense,
                              ),
                            ));
                            if (res == UpdateEnum.updated) {
                              cubit.setUpdateState(UpdateEnum.updated);
                              await cubit.refresh();
                            }
                            if (res == UpdateEnum.deleted) {
                              if (!mounted) return;
                              Navigator.of(context).pop(UpdateEnum.deleted);
                            }
                          },
                          icon: const Icon(Icons.edit),
                        ),
                    ],
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.expenseAmount,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          NumberFormat.simpleCurrency()
                              .format(state.expense.amount.abs()),
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (state.expense.description != null)
                          Card(
                            margin: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: MarkdownBody(
                                data: state.expense.description!,
                                shrinkWrap: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  blockquoteDecoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color ??
                                        Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                ),
                                imageBuilder: (uri, title, alt) =>
                                    CachedNetworkImage(
                                  imageUrl: uri.toString(),
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                onTapLink: (text, href, title) {
                                  if (href != null && isValidUrl(href)) {
                                    openUrl(context, href);
                                  }
                                },
                              ),
                            ),
                          ),
                        if (state.expense.category != null)
                          ListTile(
                            title: Text(
                              "${AppLocalizations.of(context)!.category} ${state.expense.category!.name}",
                            ),
                          ),
                        ListTile(
                          title: Text(
                            "${state.expense.isIncome ? AppLocalizations.of(context)!.expenseReceivedBy : AppLocalizations.of(context)!.expensePaidBy} ${state.household.member?.firstWhereOrNull(
                                  (e) => e.id == state.expense.paidById,
                                )?.name ?? AppLocalizations.of(context)!.other}",
                          ),
                          trailing: state.expense.date != null
                              ? Text(
                                  DateFormat.yMMMEd()
                                      .add_jm()
                                      .format(state.expense.date!),
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${state.expense.isIncome ? AppLocalizations.of(context)!.expenseReceivedFor : AppLocalizations.of(context)!.expensePaidFor}:',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(AppLocalizations.of(context)!.expenseFactor),
                            ],
                          ),
                        ),
                        const Divider(indent: 16, endIndent: 16),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ListTile(
                        title: Text(
                          state.household.member
                                  ?.firstWhereOrNull(
                                    (e) =>
                                        e.id == state.expense.paidFor[i].userId,
                                  )
                                  ?.name ??
                              AppLocalizations.of(context)!.other,
                        ),
                        subtitle: Text(NumberFormat.simpleCurrency().format(
                          (state.expense.amount *
                                  state.expense.paidFor[i].factor /
                                  state.expense.paidFor
                                      .fold(0, (p, v) => p + v.factor))
                              .abs(),
                        )),
                        trailing: Text(
                          state.expense.paidFor[i].factor.toString(),
                        ),
                      ),
                      childCount: state.expense.paidFor.length,
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
