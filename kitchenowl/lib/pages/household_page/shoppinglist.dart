import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/cubits/settings_cubit.dart';
import 'package:kitchenowl/cubits/shoppinglist_cubit.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/location_service.dart';
import 'package:kitchenowl/widgets/choice_scroll.dart';
import 'package:kitchenowl/widgets/shopping_list/shopping_list_choice_chip.dart';
import 'package:kitchenowl/widgets/shopping_list/sliver_shopinglist_item_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ShoppinglistPage extends StatefulWidget {
  const ShoppinglistPage({super.key});

  @override
  _ShoppinglistPageState createState() => _ShoppinglistPageState();
}

class _ShoppinglistPageState extends State<ShoppinglistPage>
    with WidgetsBindingObserver {
  final TextEditingController searchController = TextEditingController();
  bool _checkingLocation = false;
  // The shopping list whose location the user is currently at and that was
  // already offered/switched to. Reset once the user leaves the location.
  int? _handledLocationShoppingListId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);
    searchController.text = cubit.query;
    if (BlocProvider.of<SettingsCubit>(context).state.shoppingListKeepAwake) {
      WakelockPlus.enable();
    }
    if (cubit.state.shoppinglists.isNotEmpty) {
      _checkLocation();
    } else {
      cubit.stream
          .firstWhere((state) => state.shoppinglists.isNotEmpty)
          .then((_) => _checkLocation())
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLocation();
  }

  /// Switches to the shopping list assigned to the current location
  Future<void> _checkLocation() async {
    if (_checkingLocation || !mounted) return;
    final settings = BlocProvider.of<SettingsCubit>(context).state.location;
    if (!settings.enabled || !settings.autoSwitch) return;
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);
    if (!cubit.state.shoppinglists.values
        .any((list) => list.locations.isNotEmpty)) {
      return;
    }

    _checkingLocation = true;
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null || !mounted) return;
      final match = LocationService.findShoppingListAt(
        cubit.state.shoppinglists.values,
        position.latitude,
        position.longitude,
      );
      if (match == null) {
        _handledLocationShoppingListId = null;
        return;
      }
      final (shoppingList, location) = match;
      if (shoppingList.id == _handledLocationShoppingListId) return;
      _handledLocationShoppingListId = shoppingList.id;
      if (shoppingList.id == cubit.state.selectedShoppinglistId) return;

      if (settings.confirmSwitch) {
        final confirmed = await askForConfirmation(
          context: context,
          title: Text(AppLocalizations.of(context)!.locationSwitchConfirmTitle),
          content: Text(
            AppLocalizations.of(context)!.locationSwitchConfirmContent(
              (location.name?.isNotEmpty ?? false)
                  ? location.name!
                  : shoppingList.name,
              shoppingList.name,
            ),
          ),
          confirmText: AppLocalizations.of(context)!.yes,
          confirmBackgroundColor: null,
          confirmForegroundColor: null,
        );
        if (!confirmed || !mounted) return;
        cubit.setShoppingList(shoppingList);
      } else {
        cubit.setShoppingList(shoppingList);
        showSnackbar(
          context: context,
          width: null,
          content: Text(
            AppLocalizations.of(context)!.locationSwitched(shoppingList.name),
          ),
        );
      }
    } finally {
      _checkingLocation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<ShoppinglistCubit>(context);

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: BlocListener<ShoppinglistCubit, ShoppinglistCubitState>(
                bloc: cubit,
                listener: (context, state) {
                  if (state is! SearchShoppinglistCubitState &&
                      state is! LoadingShoppinglistCubitState) {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                    }
                  }
                },
                child: SearchTextField(
                  controller: searchController,
                  onSearch: (s) => cubit.search(s),
                  onSubmitted: () {
                    final state = cubit.state;
                    if (state is SearchShoppinglistCubitState) {
                      if (state.result.first is! ShoppinglistItem) {
                        cubit.add(state.result.first);
                      }
                    } else {
                      cubit.search(searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ShoppinglistCubit, ShoppinglistCubitState>(
              bloc: cubit,
              builder: (context, state) {
                final header = LeftRightWrap(
                  left: (state.shoppinglists.length < 2)
                      ? const SizedBox()
                      : ChoiceScroll(
                          children: state.shoppinglists.values
                              .sorted((a, b) =>
                                  b.items.length.compareTo(a.items.length))
                              .map(
                                (shoppinglist) => ShoppingListChoiceChip(
                                  shoppingList: shoppinglist,
                                  selected: shoppinglist.id ==
                                      state.selectedShoppinglistId,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      cubit.setShoppingList(
                                        shoppinglist,
                                      );
                                    }
                                  },
                                ),
                              )
                              .toList(),
                        ),
                  right: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 6),
                    child: TrailingIconTextButton(
                      onPressed: cubit.incrementSorting,
                      text: state.sorting == ShoppinglistSorting.alphabetical
                          ? AppLocalizations.of(context)!.sortingAlphabetical
                          : state.sorting == ShoppinglistSorting.algorithmic
                              ? AppLocalizations.of(context)!.sortingAlgorithmic
                              : AppLocalizations.of(context)!.category,
                      icon: const Icon(Icons.sort),
                    ),
                  ),
                );

                if (state is! SearchShoppinglistCubitState &&
                    state is! LoadingShoppinglistCubitState &&
                    (state.selectedShoppinglist?.items.isEmpty ?? true) &&
                    ((state.selectedShoppinglist?.recentItems.isEmpty ??
                            true) ||
                        (App.settings.recentItemsCount == 0))) {
                  return Column(
                    children: [
                      header,
                      const Spacer(),
                      const Icon(Icons.remove_shopping_cart_rounded),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.shoppingListEmpty,
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  );
                }
                return BlocBuilder<SettingsCubit, SettingsState>(
                  buildWhen: (previous, current) =>
                      previous.shoppingListListView !=
                          current.shoppingListListView ||
                      previous.listStyle != current.listStyle ||
                      previous.gridSize != current.gridSize,
                  builder: (context, settingsState) => PageTransitionSwitcher(
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        fillColor: Colors.transparent,
                        child: child,
                      );
                    },
                    child: (state is SearchShoppinglistCubitState)
                        ? RefreshIndicator(
                            onRefresh: cubit.refresh,
                            child: CustomScrollView(
                              primary: true,
                              slivers: [
                                SliverItemGridList(
                                  shoppingListStyle: ShoppingListStyle(
                                    listStyle: settingsState.listStyle,
                                    isList: settingsState.shoppingListListView,
                                    gridSize: settingsState.gridSize,
                                  ),
                                  items: state.result,
                                  categories: state.categories,
                                  shoppingList: state.selectedShoppinglist,
                                  onRefresh: () => cubit.refresh(),
                                  selected: (item) =>
                                      item is ShoppinglistItem &&
                                      (App.settings.shoppingListTapToRemove ||
                                          !state.selectedListItems
                                              .contains(item)),
                                  isLoading:
                                      state is LoadingShoppinglistCubitState,
                                  onPressed: Nullable((Item item) {
                                    if (item is ShoppinglistItem) {
                                      if (App
                                          .settings.shoppingListTapToRemove) {
                                        cubit.remove(item);
                                      } else {
                                        cubit.selectItem(item);
                                      }
                                    } else {
                                      cubit.add(item);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          )
                        : NestedScrollView(
                            headerSliverBuilder:
                                (context, innerBoxIsScrolled) => [
                              SliverToBoxAdapter(child: header),
                            ],
                            body: RefreshIndicator(
                              onRefresh: cubit.refresh,
                              displacement: 0,
                              child: PageTransitionSwitcher(
                                transitionBuilder: (
                                  Widget child,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation,
                                ) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.vertical,
                                    fillColor: Colors.transparent,
                                    child: child,
                                  );
                                },
                                child: CustomScrollView(
                                  key: PageStorageKey<int?>(
                                      state.selectedShoppinglistId),
                                  slivers: [
                                    SliverShopinglistItemView(
                                      shoppingListStyle: ShoppingListStyle(
                                        listStyle: settingsState.listStyle,
                                        isList:
                                            settingsState.shoppingListListView,
                                        gridSize: settingsState.gridSize,
                                      ),
                                      categories: state.categories,
                                      isLoading: state
                                          is LoadingShoppinglistCubitState,
                                      selectedListItems:
                                          state.selectedListItems,
                                      sorting: state.sorting,
                                      shoppingList: state.selectedShoppinglist,
                                      onPressed: Nullable((Item item) {
                                        if (item is ShoppinglistItem) {
                                          if (App.settings
                                              .shoppingListTapToRemove) {
                                            cubit.remove(item);
                                          } else {
                                            cubit.selectItem(item);
                                          }
                                        } else {
                                          cubit.add(item);
                                        }
                                      }),
                                      onRecentPressed: Nullable(cubit.add),
                                      onRefresh: cubit.refresh,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
