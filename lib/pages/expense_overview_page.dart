import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kitchenowl/cubits/expense_overview_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/widgets/chart_bar_member_distribution.dart';
import 'package:kitchenowl/widgets/chart_bar_months.dart';
import 'package:kitchenowl/widgets/expense_category_icon.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sliver_tools/sliver_tools.dart';

class ExpenseOverviewPage extends StatefulWidget {
  final Household household;
  final ExpenselistSorting initialSorting;

  const ExpenseOverviewPage({
    super.key,
    required this.household,
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
    cubit = ExpenseOverviewCubit(widget.household, widget.initialSorting);
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
      body: BlocBuilder<ExpenseOverviewCubit, ExpenseOverviewState>(
        bloc: cubit,
        buildWhen: (previous, current) =>
            previous != current && previous.sorting == current.sorting,
        builder: (context, state) {
          if (state is! ExpenseOverviewLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalForSelectedMonth =
              state.getTotalForMonth(state.selectedMonthIndex);

          return CustomScrollView(
            slivers: [
              SliverCrossAxisPadded.symmetric(
                padding: 16,
                child: SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 1600,
                  alignment: 0.5,
                  child: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                cubit.pagePrev(getValueForScreenType<int>(
                              context: context,
                              mobile: 5,
                              tablet: 7,
                              desktop: 10,
                            )),
                            icon: const Icon(Icons.keyboard_arrow_left_rounded),
                          ),
                          Expanded(
                            child: Text(
                              "${_monthOffsetToString(state.currentMonthOffset + 4)} - ${state.currentMonthOffset == 0 ? AppLocalizations.of(context)!.now : _monthOffsetToString(state.currentMonthOffset)}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: state.currentMonthOffset > 0
                                ? cubit.pageNext
                                : null,
                            icon:
                                const Icon(Icons.keyboard_arrow_right_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: ChartBarMonths(
                          data: state.categoryOverviewsByCategory,
                          categories: state.categories,
                          onMonthSelect: cubit.setSelectedMonth,
                          selectedMonth: state.selectedMonthIndex,
                          monthOffset: state.currentMonthOffset,
                          numberOfMonthsToShow: getValueForScreenType<int>(
                            context: context,
                            mobile: 5,
                            tablet: 7,
                            desktop: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .expenseOverviewTotalTitle(
                                _monthOffsetToString(state.selectedMonthIndex),
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            NumberFormat.simpleCurrency().format(
                              totalForSelectedMonth,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                    ]),
                  ),
                ),
              ),
              SliverCrossAxisPadded.symmetric(
                padding: 16,
                child: SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 1600,
                  alignment: 0.5,
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final entry = state
                            .categoryOverviewsByCategory[
                                state.selectedMonthIndex]!
                            .entries
                            .sorted((a, b) => b.value.compareTo(a.value))
                            .elementAt(i);
                        final amount = entry.value;
                        final category = entry.key < 0
                            ? null
                            : state.categories
                                .firstWhereOrNull((e) => e.id == entry.key);

                        return Card(
                          child: ListTile(
                            leading: Padding(
                              padding: (amount / totalForSelectedMonth >= 0)
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.all(4.0),
                              child: ExpenseCategoryIcon(
                                name: category?.name ?? '🪙',
                                color: category?.color,
                              ),
                            ),
                            title: Text(category?.name ??
                                AppLocalizations.of(context)!.other),
                            trailing: Text(
                              NumberFormat.simpleCurrency().format(amount),
                            ),
                            subtitle: (amount / totalForSelectedMonth >= 0)
                                ? Text(NumberFormat.percentPattern()
                                    .format(amount / totalForSelectedMonth))
                                : null,
                          ),
                        );
                      },
                      childCount: state
                              .categoryOverviewsByCategory[
                                  state.selectedMonthIndex]
                              ?.length ??
                          0,
                    ),
                  ),
                ),
              ),
              SliverCrossAxisPadded.symmetric(
                padding: 16,
                child: SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 1600,
                  alignment: 0.5,
                  child: SliverList.list(children: [
                    const Divider(),
                    ChartBarMemberDistribution(
                      household: state.household,
                    ),
                  ]),
                ),
              ),
              SliverCrossAxisPadded.symmetric(
                padding: 16,
                child: SliverCrossAxisConstrained(
                  maxCrossAxisExtent: 1600,
                  alignment: 0.5,
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Card(
                        child: ListTile(
                          title: Text(AppLocalizations.of(context)!.owesAB(
                            state.owes[i].$1.name,
                            state.owes[i].$2.name,
                          )),
                          trailing: Text(NumberFormat.simpleCurrency()
                              .format(state.owes[i].$3)),
                        ),
                      ),
                      childCount: state.owes.length,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _monthOffsetToString(int offset) {
    return DateFormat.MMMM()
        .dateSymbols
        .STANDALONEMONTHS[(DateTime.now().month - 1 - offset) % 12];
  }
}
