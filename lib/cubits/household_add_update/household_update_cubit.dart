import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';

import 'household_add_update_cubit.dart';

class HouseholdUpdateCubit
    extends HouseholdAddUpdateCubit<HouseholdUpdateState> {
  final Household household;

  HouseholdUpdateCubit(this.household)
      : super(LoadingHouseholdUpdateState(
          name: household.name,
          image: household.image,
          featureExpenses: household.featureExpenses ?? true,
          featurePlanner: household.featurePlanner ?? true,
          viewOrdering: household.viewOrdering ?? ViewsEnum.values,
          member: household.member ?? const [],
        )) {
    refresh();
  }

  Future<void> refresh() async {
    Future<Household?> fHousehold =
        ApiService.getInstance().getHousehold(this.household);

    Future<List<ShoppingList>?> shoppingLists =
        ApiService.getInstance().getShoppingLists(this.household);
    Future<Set<Tag>?> tags =
        ApiService.getInstance().getAllTags(this.household);
    Future<List<Category>?> categories =
        ApiService.getInstance().getCategories(this.household);
    Future<List<ExpenseCategory>?> expenseCategories =
        ApiService.getInstance().getExpenseCategories(this.household);

    Household household = await fHousehold ?? this.household;

    emit(HouseholdUpdateState(
      name: household.name,
      featureExpenses: household.featureExpenses ?? true,
      featurePlanner: household.featurePlanner ?? true,
      viewOrdering: household.viewOrdering ?? ViewsEnum.values,
      member: household.member ?? this.household.member ?? const [],
      shoppingLists: await shoppingLists ?? const [],
      tags: await tags ?? {},
      categories: await categories ?? const [],
      expenseCategories: await expenseCategories ?? const [],
    ));
  }

  @override
  void setName(String name) {
    if (name.replaceAll(" ", "").isNotEmpty) {
      emit(state.copyWith(name: name));
      saveHousehold();
    }
  }

  @override
  void setImage(NamedByteArray image) {
    // TODO: implement setImage
  }

  @override
  void setView(ViewsEnum view, bool value) {
    if (view == ViewsEnum.planner) {
      emit(state.copyWith(featurePlanner: value));
      saveHousehold();
    }
    if (view == ViewsEnum.balances) {
      emit(state.copyWith(featureExpenses: value));
      saveHousehold();
    }
  }

  @override
  void reorderView(int oldIndex, int newIndex) {
    final l = List.of(state.viewOrdering);
    l.insert(newIndex, l.removeAt(oldIndex));
    emit(state.copyWith(viewOrdering: l));
    saveHousehold();
  }

  @override
  void resetViewOrder() {
    emit(state.copyWith(viewOrdering: ViewsEnum.values));
    saveHousehold();
  }

  void saveHousehold() {
    ApiService.getInstance().updateHousehold(household.copyWith(
      featureExpenses: state.featureExpenses,
      featurePlanner: state.featurePlanner,
      viewOrdering: state.viewOrdering,
    ));
  }

  Future<bool> addTag(String name) async {
    final res =
        await ApiService.getInstance().addTag(household, Tag(name: name));
    refresh();

    return res;
  }

  Future<bool> deleteTag(Tag tag) async {
    final res = await ApiService.getInstance().deleteTag(tag);
    refresh();

    return res;
  }

  Future<bool> updateTag(Tag tag) async {
    final res = await ApiService.getInstance().updateTag(tag);
    refresh();

    return res;
  }

  Future<bool> deleteShoppingList(ShoppingList shoppingList) async {
    if (shoppingList.id == 1) return false;
    final res = await ApiService.getInstance()
        .deleteShoppingList(household, shoppingList);
    refresh();

    return res;
  }

  Future<bool> addShoppingList(String name) async {
    final res = await ApiService.getInstance()
        .addShoppingList(household, ShoppingList(name: name));
    refresh();

    return res;
  }

  Future<bool> updateShoppingList(ShoppingList shoppingList) async {
    final res = await ApiService.getInstance()
        .updateShoppingList(household, shoppingList);
    refresh();

    return res;
  }

  Future<bool> deleteCategory(Category category) async {
    final res = await ApiService.getInstance().deleteCategory(category);
    refresh();

    return res;
  }

  Future<bool> addCategory(String name) async {
    final res = await ApiService.getInstance()
        .addCategory(household, Category(name: name));
    refresh();

    return res;
  }

  Future<bool> updateCategory(Category category) async {
    final res = await ApiService.getInstance().updateCategory(category);
    refresh();

    return res;
  }

  Future<bool> reorderCategory(int oldIndex, int newIndex) async {
    final l = List<Category>.of(state.categories);
    final category = l.removeAt(oldIndex);
    l.insert(newIndex, category);
    emit(state.copyWith(categories: l));

    final res = await ApiService.getInstance()
        .updateCategory(category.copyWith(ordering: newIndex));

    refresh();

    return res;
  }

  Future<bool> deleteExpenseCategory(ExpenseCategory category) async {
    final res = await ApiService.getInstance().deleteExpenseCategory(category);
    refresh();

    return res;
  }

  Future<bool> addExpenseCategory(ExpenseCategory category) async {
    final res =
        await ApiService.getInstance().addExpenseCategory(household, category);
    refresh();

    return res;
  }

  Future<bool> updateExpenseCategory(ExpenseCategory category) async {
    final res = await ApiService.getInstance()
        .updateExpenseCategory(household, category);
    refresh();

    return res;
  }

  @override
  Future<void> setLanguage(String langCode) {
    return ApiService.getInstance().importLanguage(
      household,
      langCode,
    );
  }
}

class HouseholdUpdateState extends HouseholdAddUpdateState {
  final String? image;
  final List<Member> member;
  final List<ShoppingList> shoppingLists;
  final Set<Tag> tags;
  final List<Category> categories;
  final List<ExpenseCategory> expenseCategories;

  const HouseholdUpdateState({
    super.name,
    this.image,
    super.featurePlanner = true,
    super.featureExpenses = true,
    super.viewOrdering = ViewsEnum.values,
    this.member = const [],
    this.shoppingLists = const [],
    this.tags = const {},
    this.categories = const [],
    this.expenseCategories = const [],
  });

  HouseholdUpdateState copyWith({
    String? name,
    String? image,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
    List<Member>? member,
    List<ShoppingList>? shoppingLists,
    Set<Tag>? tags,
    List<Category>? categories,
    List<ExpenseCategory>? expenseCategories,
  }) =>
      HouseholdUpdateState(
        name: name ?? this.name,
        image: image ?? this.image,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        member: member ?? this.member,
        shoppingLists: shoppingLists ?? this.shoppingLists,
        tags: tags ?? this.tags,
        categories: categories ?? this.categories,
        expenseCategories: expenseCategories ?? this.expenseCategories,
      );

  @override
  List<Object?> get props =>
      super.props +
      [
        image,
        member,
        shoppingLists,
        tags,
        categories,
        expenseCategories,
      ];
}

class LoadingHouseholdUpdateState extends HouseholdUpdateState {
  const LoadingHouseholdUpdateState({
    super.name,
    super.image,
    super.featureExpenses,
    super.featurePlanner,
    super.viewOrdering,
    super.member,
  });
}
