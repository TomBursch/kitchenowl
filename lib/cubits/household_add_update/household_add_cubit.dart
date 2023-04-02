import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

import 'household_add_update_cubit.dart';

class HouseholdAddCubit extends HouseholdAddUpdateCubit<HouseholdAddState> {
  HouseholdAddCubit() : super(const HouseholdAddState());

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

  Future<void> create() async {
    final _state = state;
    if (!_state.isValid()) return;
    String? image;
    if (_state.image != null) {
      image = _state.image!.isEmpty
          ? ''
          : await ApiService.getInstance().uploadBytes(_state.image!);
    }

    ApiService.getInstance().addHousehold(Household(
      id: 0,
      name: _state.name,
      image: image,
      language: _state.language,
      featurePlanner: _state.featurePlanner,
      featureExpenses: _state.featureExpenses,
      viewOrdering: _state.viewOrdering,
    ));
  }

  @override
  Future<void> setLanguage(String langCode) {
    emit(state.copyWith(language: langCode));

    return Future.value();
  }
}

class HouseholdAddState extends HouseholdAddUpdateState {
  final NamedByteArray? image;

  const HouseholdAddState({
    super.name = "",
    this.image,
    super.language,
    super.featurePlanner = true,
    super.featureExpenses = true,
    super.viewOrdering = ViewsEnum.values,
  });

  HouseholdAddState copyWith({
    String? name,
    NamedByteArray? image,
    String? language,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
  }) =>
      HouseholdAddState(
        name: name ?? this.name,
        image: image ?? this.image,
        language: language ?? this.language,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
      );

  @override
  List<Object?> get props => super.props + [image];

  bool isValid() => name.isNotEmpty;
}
