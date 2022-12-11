import 'package:kitchenowl/enums/views_enum.dart';

import 'model.dart';

class ServerSettings extends Model {
  final bool? featurePlanner;
  final bool? featureExpenses;
  final List<ViewsEnum>? viewOrdering;

  const ServerSettings({
    this.featurePlanner,
    this.featureExpenses,
    this.viewOrdering,
  });

  factory ServerSettings.fromJson(Map<String, dynamic> map) {
    List<ViewsEnum> viewOrdering = ViewsEnum.values;
    if (map.containsKey('view_ordering')) {
      viewOrdering = ViewsEnum.addMissing(List.from(map['view_ordering']
          .map((e) => ViewsEnum.parse(e))
          .where((e) => e != null)));
    }

    return ServerSettings(
      featurePlanner: map['planner_feature'] ?? false,
      featureExpenses: map['expenses_feature'] ?? false,
      viewOrdering: viewOrdering,
    );
  }

  @override
  List<Object?> get props => [featurePlanner, featureExpenses, viewOrdering];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    if (featurePlanner != null) {
      data['planner_feature'] = featurePlanner;
    }
    if (featureExpenses != null) {
      data['expenses_feature'] = featureExpenses;
    }
    if (viewOrdering != null) {
      data['view_ordering'] = viewOrdering!.map((e) => e.toString()).toList()
        ..remove(ViewsEnum.profile.toString());
    }

    return data;
  }

  ServerSettings copyWith({
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
  }) =>
      ServerSettings(
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
      );

  ServerSettings copyFrom(ServerSettings serverSettings) => ServerSettings(
        featurePlanner: serverSettings.featurePlanner ?? featurePlanner,
        featureExpenses: serverSettings.featureExpenses ?? featureExpenses,
        viewOrdering: serverSettings.viewOrdering ?? viewOrdering,
      );
}
