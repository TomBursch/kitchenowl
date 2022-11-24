import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_overview_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/widgets/chart_pie_current_month.dart';
import 'package:kitchenowl/widgets/chart_bar_months.dart';

class ExpenseOverviewPage extends StatefulWidget {
  final ExpenselistSorting initialSorting;

  const ExpenseOverviewPage({
    super.key,
    this.initialSorting = ExpenselistSorting.all,
  });

  @override
  State<ExpenseOverviewPage> createState() => _ExpenseOverviewPageState();
}

class _ExpenseOverviewPageState extends State<ExpenseOverviewPage> {
  late final ExpenseOverviewCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = ExpenseOverviewCubit(widget.initialSorting);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.overview),
        actions: [
          BlocBuilder<ExpenseOverviewCubit, ExpenseOverviewState>(
            bloc: cubit,
            buildWhen: (previous, current) =>
                previous.sorting != current.sorting,
            builder: (context, state) {
              return Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: cubit.incrementSorting,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.sorting == ExpenselistSorting.all
                              ? AppLocalizations.of(context)!.household
                              : state.sorting == ExpenselistSorting.personal
                                  ? AppLocalizations.of(context)!.personal
                                  : AppLocalizations.of(context)!.other,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.sort),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(width: 1600),
          child: BlocBuilder<ExpenseOverviewCubit, ExpenseOverviewState>(
            bloc: cubit,
            buildWhen: (previous, current) =>
                previous != current && previous.sorting == current.sorting,
            builder: (context, state) {
              if (state is! ExpenseOverviewLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!
                              .expenseOverviewTotalTitle(
                            _monthOffsetToString(0),
                          ),
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      Text(
                        NumberFormat.simpleCurrency()
                            .format(state.getTotalForMonth(0)),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: ChartPieCurrentMonth(
                      data: state.categoryOverviewsByCategory['0']!,
                      availableHeight: 270,
                    ),
                  ),
                  const Divider(),
                  Text(
                    AppLocalizations.of(context)!
                        .expenseOverviewComparedToPreviousMonth,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 300,
                    child: ChartBarMonths(
                      data: state.categoryOverviewsByCategory,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _monthOffsetToString(int offset) {
    return DateFormat.MMMM()
        .dateSymbols
        .STANDALONEMONTHS[(DateTime.now().month - 1 - offset) % 12];
  }
}
