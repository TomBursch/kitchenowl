import 'dart:io';

import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/expense_category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/import_settings.dart';
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
          language: household.language,
        )) {
    refresh();
    ApiService.getInstance()
        .getSupportedLanguages()
        .then((value) => emit(state.copyWith(supportedLanguages: value)));
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
      language: household.language,
      image: household.image,
      shoppingLists: await shoppingLists ?? const [],
      tags: await tags ?? {},
      categories: await categories ?? const [],
      expenseCategories: await expenseCategories ?? const [],
      supportedLanguages: state.supportedLanguages,
    ));
  }

  @override
  void setName(String name) {
    if (name.replaceAll(" ", "").isNotEmpty) {
      emit(state.copyWith(name: name.trim()));
      saveHousehold();
    }
  }

  @override
  void setImage(NamedByteArray image) async {
    final imageUrl =
        image.isEmpty ? '' : await ApiService.getInstance().uploadBytes(image);
    emit(state.copyWith(image: imageUrl));
    saveHousehold();
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

  Future<bool> saveHousehold() {
    return ApiService.getInstance().updateHousehold(household.copyWith(
      name: state.name,
      image: state.image,
      language: state.language,
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

  Future<bool> mergeTag(Tag tag, Tag other) async {
    final res = await ApiService.getInstance().mergeTag(tag, other);
    refresh();

    return res;
  }

  Future<bool> deleteShoppingList(ShoppingList shoppingList) async {
    if (household.defaultShoppingList == shoppingList) return false;
    final res = await ApiService.getInstance().deleteShoppingList(shoppingList);
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
    final res = await ApiService.getInstance().updateShoppingList(shoppingList);
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

  Future<bool> mergeCategory(Category category, Category other) async {
    final res = await ApiService.getInstance().mergeCategories(category, other);
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
    final res = await ApiService.getInstance().updateExpenseCategory(category);
    refresh();

    return res;
  }

  Future<bool> mergeExpenseCategory(
    ExpenseCategory category,
    ExpenseCategory other,
  ) async {
    final res =
        await ApiService.getInstance().mergeExpenseCategories(category, other);
    refresh();

    return res;
  }

  @override
  Future<void> setLanguage(String? langCode) {
    if (state.language?.isNotEmpty ?? false) return Future.value();

    emit(state.copyWith(language: langCode));

    return saveHousehold();
  }

  Future<bool> deleteHousehold() {
    return ApiService.getInstance().deleteHousehold(household);
  }

  Future<void> exportHousehold(String path) async {
    try {
      final content = await ApiService.getInstance().exportHousehold(household);
      if (content != null) File(path).writeAsString(content);
    } catch (_) {}
  }

  Future<String?> getExportHousehold() {
    return ApiService.getInstance().exportHousehold(household);
  }

  Future<void> importHousehold(
    Map<String, dynamic> content, [
    ImportSettings settings = const ImportSettings(),
  ]) async {
    content = {
      if (settings.items) "items": content["items"],
      if (settings.recipes) "recipes": content["recipes"],
      if (settings.expenses) "expenses": content["expenses"],
      if (settings.shoppinglists) "shoppinglists": content["shoppinglists"],
    };
    await ApiService.getInstance()
        .importHousehold(household, content, settings.recipesOverwrite);
  }
}

class HouseholdUpdateState extends HouseholdAddUpdateState {
  final String? image;
  final List<ShoppingList> shoppingLists;
  final Set<Tag> tags;
  final List<Category> categories;
  final List<ExpenseCategory> expenseCategories;

  const HouseholdUpdateState({
    super.name,
    this.image,
    super.language,
    super.featurePlanner = true,
    super.featureExpenses = true,
    super.viewOrdering = ViewsEnum.values,
    super.supportedLanguages,
    this.shoppingLists = const [],
    this.tags = const {},
    this.categories = const [],
    this.expenseCategories = const [],
  });

  HouseholdUpdateState copyWith({
    String? name,
    String? image,
    String? language,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
    Map<String, String>? supportedLanguages,
    List<Member>? member,
    List<ShoppingList>? shoppingLists,
    Set<Tag>? tags,
    List<Category>? categories,
    List<ExpenseCategory>? expenseCategories,
  }) =>
      HouseholdUpdateState(
        name: name ?? this.name,
        image: image ?? this.image,
        language: language ?? this.language,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        supportedLanguages: supportedLanguages ?? this.supportedLanguages,
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
    super.language,
    super.supportedLanguages,
  });

  @override
  HouseholdUpdateState copyWith({
    String? name,
    String? image,
    String? language,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
    Map<String, String>? supportedLanguages,
    List<Member>? member,
    List<ShoppingList>? shoppingLists,
    Set<Tag>? tags,
    List<Category>? categories,
    List<ExpenseCategory>? expenseCategories,
  }) =>
      LoadingHouseholdUpdateState(
        name: name ?? this.name,
        image: image ?? this.image,
        language: language ?? this.language,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      );
}
