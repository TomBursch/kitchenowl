import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/expense_overview_page.dart';
import 'package:kitchenowl/widgets/chart_pie_current_month.dart';
import 'package:kitchenowl/widgets/expense_item.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  _ExpensePageState createState() => _ExpensePageState();

  @override
  void onSelected(BuildContext context, bool alreadySelected) {
    BlocProvider.of<ExpenseListCubit>(context).refresh();
    // if (scrollController.hasClients) scrollController.jumpTo(0);
  }
}

class _ExpensePageState extends State<ExpenseListPage> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListen);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ExpenseListCubit>(context);

    return SafeArea(
      child: Scrollbar(
        controller: scrollController,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<ExpenseListCubit, ExpenseListCubitState>(
            bloc: cubit,
            builder: (context, state) => CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      height: 80,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.balances,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (state.expenses.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(50),
                              child: const Icon(Icons.bar_chart_rounded),
                              onTap: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .push(
                                MaterialPageRoute(
                                  builder: (ctx) => ExpenseOverviewPage(
                                    household:
                                        BlocProvider.of<ExpenseListCubit>(
                                      context,
                                    ).household,
                                    initialSorting: state.sorting,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state is LoadingExpenseListCubitState && !App.isOffline)
                  SliverList(
                    delegate: SliverChildListDelegate([
                      SizedBox(
                        height: (2 * 60 + 30).toDouble(),
                      ),
                      for (int i = 0; i < 3; i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                          child: ShimmerCard(
                            trailing: ShimmerText(
                              maxWidth: 50,
                            ),
                          ),
                        ),
                    ]),
                  ),
                if (state.household.member?.isNotEmpty ?? false) ...[
                  SliverToBoxAdapter(
                    child: AnimatedCrossFade(
                      crossFadeState: state.sorting == ExpenselistSorting.all ||
                              state.categoryOverview.isEmpty
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 100),
                      firstChild: SizedBox(
                        height:
                            ((state.household.member?.length ?? 0) * 60 + 30)
                                .toDouble(),
                        child: _getBarChart(context, state),
                      ),
                      secondChild: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 270,
                          child: Row(
                            children: [
                              if (state.categoryOverview.values
                                      .fold(0.0, (a, b) => a + b) !=
                                  0)
                                Expanded(
                                  flex: 2,
                                  child: ChartPieCurrentMonth(
                                    data: state.categoryOverview,
                                    categories: state.categories,
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat.MMMM()
                                              .dateSymbols
                                              .STANDALONEMONTHS[
                                          DateTime.now().month - 1],
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const Divider(),
                                    Text(
                                      NumberFormat.simpleCurrency().format(state
                                          .categoryOverview.values
                                          .fold(0.0, (a, b) => a + b)),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.expenses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(right: 16),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TrailingIconTextButton(
                            text: state.sorting == ExpenselistSorting.all
                                ? AppLocalizations.of(context)!.household
                                : state.sorting == ExpenselistSorting.personal
                                    ? AppLocalizations.of(context)!.personal
                                    : AppLocalizations.of(context)!.other,
                            icon: const Icon(Icons.sort),
                            onPressed: cubit.incrementSorting,
                          ),
                        ),
                      ),
                    ),
                  if (state.expenses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverImplicitAnimatedList(
                        itemBuilder: (context, i, animation) => SizeTransition(
                          key: ValueKey(state.expenses[i].id),
                          sizeFactor: animation,
                          child: ExpenseItemWidget(
                            expense: state.expenses[i],
                            onUpdated: cubit.refresh,
                            displayPersonalAmount:
                                state.sorting == ExpenselistSorting.personal,
                          ),
                        ),
                        removeItemBuilder: (context, expense, animation) =>
                            SizeTransition(
                          key: ValueKey(expense.id),
                          sizeFactor: animation,
                          child: ExpenseItemWidget(
                            expense: expense,
                            onUpdated: cubit.refresh,
                            displayPersonalAmount:
                                state.sorting == ExpenselistSorting.personal,
                          ),
                        ),
                        items: state.expenses,
                        equalityChecker: (p0, p1) => p0.id == p1.id,
                      ),
                    ),
                ],
                if (state.expenses.isEmpty && !App.isOffline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.money_off_rounded),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.expenseEmpty),
                        ],
                      ),
                    ),
                  ),
                if (state.expenses.isEmpty && App.isOffline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.offlineMessage),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollListen() {
    if ((scrollController.position.pixels ==
        scrollController.position.maxScrollExtent)) {
      BlocProvider.of<ExpenseListCubit>(context).loadMore();
    }
  }

  // ignore: long-method
  Widget _getBarChart(BuildContext context, ExpenseListCubitState state) {
    double maxBalance = (state.household.member ?? [])
        .fold<double>(0.0, (p, e) => e.balance.abs() > p ? e.balance.abs() : p);
    maxBalance = maxBalance > 0 ? maxBalance : 1;

    final zeroDividerColor = Theme.of(context).colorScheme.onSurface;

    return charts.BarChart(
      [
        charts.Series<Member, String>(
          id: 'Balance',
          data: state.household.member ?? [],
          colorFn: (member, _) => charts.Color(
            r: Theme.of(context).colorScheme.primary.red,
            g: Theme.of(context).colorScheme.primary.green,
            b: Theme.of(context).colorScheme.primary.blue,
          ),
          domainFn: (member, _) => member.username,
          measureFn: (member, _) => member.balance,
          labelAccessorFn: (member, _) =>
              "  ${member.name}: ${NumberFormat.simpleCurrency().format(member.balance)}",
        ),
        charts.Series<User, String>(
          id: 'zero',
          domainFn: (member, _) => member.username,
          measureFn: (member, _) => 0,
          data: state.household.member ?? [],
          colorFn: (member, _) => charts.Color(
            r: zeroDividerColor.red,
            g: zeroDividerColor.green,
            b: zeroDividerColor.blue,
          ),
          strokeWidthPxFn: (member, _) => 5,
        )..setAttribute(charts.rendererIdKey, 'zero'),
      ],
      vertical: false,
      defaultRenderer: charts.BarRendererConfig(
        barRendererDecorator: charts.BarLabelDecorator<String>(
          insideLabelStyleSpec: charts.TextStyleSpec(
            color: charts.Color(
              r: Theme.of(context).colorScheme.onPrimary.red,
              g: Theme.of(context).colorScheme.onPrimary.green,
              b: Theme.of(context).colorScheme.onPrimary.blue,
            ),
          ),
          outsideLabelStyleSpec: charts.TextStyleSpec(
            color: charts.Color(
              r: Theme.of(context).colorScheme.onBackground.red,
              g: Theme.of(context).colorScheme.onBackground.green,
              b: Theme.of(context).colorScheme.onBackground.blue,
            ),
          ),
        ),
        cornerStrategy: const charts.ConstCornerStrategy(14),
      ),
      customSeriesRenderers: [
        charts.BarTargetLineRendererConfig<String>(
          customRendererId: 'zero',
        ),
      ],
      defaultInteractions: false,
      primaryMeasureAxis: charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: const charts.NoneRenderSpec(),
        tickProviderSpec: charts.StaticNumericTickProviderSpec([
          charts.TickSpec(-maxBalance),
          const charts.TickSpec<double>(0.0),
          charts.TickSpec(maxBalance),
        ]),
      ),
      domainAxis: const charts.OrdinalAxisSpec(
        renderSpec: charts.NoneRenderSpec(),
      ),
    );
  }
}
