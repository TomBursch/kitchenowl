import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/nullable.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

import 'household_add_update_cubit.dart';

class HouseholdAddCubit extends HouseholdAddUpdateCubit<HouseholdAddState> {
  HouseholdAddCubit(String? locale, User user)
      : super(HouseholdAddState(
          members: [Member.fromUser(user, admin: true)],
        )) {
    ApiService.getInstance()
        .getSupportedLanguages()
        .then((value) => emit(state.copyWith(
              supportedLanguages: value,
              language: Nullable(state.language ??
                  ((value?.containsKey(locale) ?? false) ? locale : null)),
            )));
  }

  @override
  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  @override
  void setImage(NamedByteArray image) {
    emit(state.copyWith(image: image));
  }

  @override
  void setView(ViewsEnum view, bool value) {
    if (view == ViewsEnum.planner) {
      emit(state.copyWith(featurePlanner: value));
    }
    if (view == ViewsEnum.balances) {
      emit(state.copyWith(featureExpenses: value));
    }
  }

  @override
  void reorderView(int oldIndex, int newIndex) {
    final l = List.of(state.viewOrdering);
    l.insert(newIndex, l.removeAt(oldIndex));
    emit(state.copyWith(viewOrdering: l));
  }

  @override
  void resetViewOrder() {
    emit(state.copyWith(viewOrdering: ViewsEnum.values));
  }

  void removeMember(Member member) {
    if (member.hasAdminRights()) return;
    final l = List.of(state.members);
    emit(state.copyWith(
      members: l..removeWhere((m) => m.id == member.id),
    ));
  }

  void addMember(Member member) {
    final l = List.of(state.members);
    emit(state.copyWith(
      members: l..add(member),
    ));
  }

  Future<Household?> create() async {
    final _state = state;
    if (!_state.isValid()) return null;
    String? image;
    if (_state.image != null) {
      image = _state.image!.isEmpty
          ? ''
          : await ApiService.getInstance().uploadBytes(_state.image!);
    }

    return ApiService.getInstance().addHousehold(Household(
      id: 0,
      name: _state.name,
      image: image,
      language: _state.language,
      featurePlanner: _state.featurePlanner,
      featureExpenses: _state.featureExpenses,
      viewOrdering: _state.viewOrdering,
      member: _state.members,
    ));
  }

  @override
  Future<void> setLanguage(String? langCode) {
    emit(state.copyWith(language: Nullable(langCode)));

    return Future.value();
  }
}

class HouseholdAddState extends HouseholdAddUpdateState {
  final NamedByteArray? image;
  final List<Member> members;

  const HouseholdAddState({
    super.name = "",
    this.image,
    super.language,
    super.featurePlanner = true,
    super.featureExpenses = true,
    super.viewOrdering = ViewsEnum.values,
    super.supportedLanguages,
    this.members = const [],
  });

  HouseholdAddState copyWith({
    String? name,
    NamedByteArray? image,
    Nullable<String>? language,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
    Map<String, String>? supportedLanguages,
    List<Member>? members,
  }) =>
      HouseholdAddState(
        name: name ?? this.name,
        image: image ?? this.image,
        language: (language ?? Nullable(this.language)).value,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
        supportedLanguages: supportedLanguages ?? this.supportedLanguages,
        members: members ?? this.members,
      );

  @override
  List<Object?> get props => super.props + [image, members];

  bool isValid() => name.replaceAll(" ", "").isNotEmpty;
}
