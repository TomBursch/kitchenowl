import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/expense_list_cubit.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/enums/expenselist_sorting.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/pages/expense_add_update_page.dart';
import 'package:kitchenowl/pages/expense_overview_page.dart';
import 'package:kitchenowl/widgets/chart_pie_current_month.dart';
import 'package:kitchenowl/widgets/expense_item.dart';

import 'home_page_item.dart';

class ExpenseListPage extends StatefulWidget with HomePageItem {
  ExpenseListPage({super.key});

  final ScrollController scrollController = ScrollController();

  @override
  _ExpensePageState createState() => _ExpensePageState();

  @override
  ViewsEnum type() => ViewsEnum.balances;

  @override
  void onSelected(BuildContext context, bool alreadySelected) {
    BlocProvider.of<ExpenseListCubit>(context).refresh();
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  @override
  bool isActive(BuildContext context) =>
      BlocProvider.of<SettingsCubit>(context)
          .state
          .serverSettings
          .featureExpenses ??
      false;

  @override
  Widget? floatingActionButton(BuildContext context) {
    if (!App.isOffline) {
      return OpenContainer(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (BuildContext ctx, VoidCallback _) {
          return AddUpdateExpensePage(
            users: BlocProvider.of<ExpenseListCubit>(context).state.users,
          );
        },
        openColor: Theme.of(context).scaffoldBackgroundColor,
        onClosed: (data) {
          if (data == UpdateEnum.updated) {
            BlocProvider.of<ExpenseListCubit>(context).refresh();
          }
        },
        closedElevation: 4.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(14),
          ),
        ),
        closedColor:
            Theme.of(context).floatingActionButtonTheme.backgroundColor ??
                Theme.of(context).colorScheme.secondary,
        closedBuilder: (
          BuildContext context,
          VoidCallback openContainer,
        ) {
          return SizedBox(
            height: 56,
            width: 56,
            child: Center(
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          );
        },
      );
    }

    return null;
  }
}

class _ExpensePageState extends State<ExpenseListPage> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListen);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ExpenseListCubit>(context);

    return SafeArea(
      child: Scrollbar(
        controller: widget.scrollController,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: BlocBuilder<ExpenseListCubit, ExpenseListCubitState>(
            bloc: cubit,
            builder: (context, state) => CustomScrollView(
              controller: widget.scrollController,
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
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          ),
                          if (state.expenses.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(50),
                              child: const Icon(Icons.bar_chart_rounded),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ExpenseOverviewPage(
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
                if (state.users.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: AnimatedCrossFade(
                      crossFadeState: state.sorting == ExpenselistSorting.all ||
                              state.categoryOverview.isEmpty
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 100),
                      firstChild: SizedBox(
                        height: (state.users.length * 60 + 30).toDouble(),
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
                                      style:
                                          Theme.of(context).textTheme.headline5,
                                    ),
                                    const Divider(),
                                    Text(
                                      NumberFormat.simpleCurrency().format(state
                                          .categoryOverview.values
                                          .fold(0.0, (a, b) => a + b)),
                                      style:
                                          Theme.of(context).textTheme.headline5,
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
                            users: state.users,
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
                            users: state.users,
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
    if ((widget.scrollController.position.pixels ==
        widget.scrollController.position.maxScrollExtent)) {
      BlocProvider.of<ExpenseListCubit>(context).loadMore();
    }
  }

  // ignore: long-method
  Widget _getBarChart(BuildContext context, ExpenseListCubitState state) {
    double maxBalance = state.users
        .fold<double>(0.0, (p, e) => e.balance.abs() > p ? e.balance.abs() : p);
    maxBalance = maxBalance > 0 ? maxBalance : 1;

    final zeroDividerColor = Theme.of(context).colorScheme.onSurface;

    return charts.BarChart(
      [
        charts.Series<User, String>(
          id: 'Balance',
          data: state.users,
          colorFn: (user, _) => charts.Color(
            r: Theme.of(context).colorScheme.primary.red,
            g: Theme.of(context).colorScheme.primary.green,
            b: Theme.of(context).colorScheme.primary.blue,
          ),
          domainFn: (user, _) => user.username,
          measureFn: (user, _) => user.balance,
          labelAccessorFn: (user, _) =>
              "  ${user.name}: ${NumberFormat.simpleCurrency().format(user.balance)}",
        ),
        charts.Series<User, String>(
          id: 'zero',
          domainFn: (user, _) => user.username,
          measureFn: (user, _) => 0,
          data: state.users,
          colorFn: (user, _) => charts.Color(
            r: zeroDividerColor.red,
            g: zeroDividerColor.green,
            b: zeroDividerColor.blue,
          ),
          strokeWidthPxFn: (user, _) => 5,
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
