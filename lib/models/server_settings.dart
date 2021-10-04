import 'model.dart';

class ServerSettings extends Model {
  final bool featurePlanner;
  final bool featureExpenses;

  const ServerSettings({this.featurePlanner, this.featureExpenses});

  factory ServerSettings.fromJson(Map<String, dynamic> map) => ServerSettings(
        featurePlanner: map['planner_feature'] ?? false,
        featureExpenses: map['expenses_feature'] ?? false,
      );

  @override
  List<Object> get props => [featurePlanner, featureExpenses];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    if (featurePlanner != null) {
      data['planner_feature'] = featurePlanner;
    }
    if (featureExpenses != null) {
      data['expenses_feature'] = featureExpenses;
    }
    return data;
  }

  ServerSettings copyWith({
    bool featurePlanner,
    bool featureExpenses,
  }) =>
      ServerSettings(
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
      );

  ServerSettings copyFrom(ServerSettings serverSettings) => ServerSettings(
        featurePlanner: serverSettings.featurePlanner ?? featurePlanner,
        featureExpenses: serverSettings.featureExpenses ?? featureExpenses,
      );
}
