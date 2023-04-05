import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';

abstract class HouseholdAddUpdateCubit<State extends HouseholdAddUpdateState>
    extends Cubit<State> {
  HouseholdAddUpdateCubit(super.initialState);

  void setName(String name);

  void setImage(NamedByteArray image);

  void setView(ViewsEnum view, bool value);

  void reorderView(int oldIndex, int newIndex);

  void resetViewOrder();

  Future<void> setLanguage(String? langCode);
}

abstract class HouseholdAddUpdateState extends Equatable {
  final String name;
  final String? language;
  final bool featurePlanner;
  final bool featureExpenses;
  final List<ViewsEnum> viewOrdering;

  final Map<String, String>? supportedLanguages;

  const HouseholdAddUpdateState({
    this.name = "",
    this.language,
    this.featurePlanner = true,
    this.featureExpenses = true,
    this.viewOrdering = ViewsEnum.values,
    this.supportedLanguages,
  });

  @override
  List<Object?> get props => [
        name,
        language,
        featurePlanner,
        featureExpenses,
        viewOrdering,
        supportedLanguages,
      ];

  bool isViewActive(ViewsEnum view) {
    if (view == ViewsEnum.planner) {
      return featurePlanner;
    }
    if (view == ViewsEnum.balances) {
      return featureExpenses;
    }

    return true;
  }
}
