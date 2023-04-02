import 'package:kitchenowl/enums/views_enum.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/models/model.dart';

class Household extends Model {
  final int id;
  final String name;
  final String? image;
  final String? language;
  final bool? featurePlanner;
  final bool? featureExpenses;
  final List<ViewsEnum>? viewOrdering;
  final List<Member>? member;

  const Household({
    required this.id,
    this.name = '',
    this.image,
    this.language,
    this.featurePlanner,
    this.featureExpenses,
    this.viewOrdering,
    this.member,
  });

  factory Household.fromJson(Map<String, dynamic> map) {
    List<ViewsEnum> viewOrdering = ViewsEnum.values;
    if (map.containsKey('view_ordering')) {
      viewOrdering = ViewsEnum.addMissing(List.from(map['view_ordering']
          .map((e) => ViewsEnum.parse(e))
          .where((e) => e != null)));
    }

    List<Member> member = const [];
    if (map.containsKey('member')) {
      member = List.from(map['member'].map((e) => Member.fromJson(e)));
    }

    return Household(
      id: map['id'],
      name: map['name'],
      image: map['photo'],
      language: map['language'],
      featurePlanner: map['planner_feature'] ?? false,
      featureExpenses: map['expenses_feature'] ?? false,
      viewOrdering: viewOrdering,
      member: member,
    );
  }

  Household copyWith({
    String? name,
    String? image,
    String? language,
    bool? featurePlanner,
    bool? featureExpenses,
    List<ViewsEnum>? viewOrdering,
  }) =>
      Household(
        id: id,
        name: name ?? this.name,
        image: image ?? this.image,
        language: language ?? this.language,
        featurePlanner: featurePlanner ?? this.featurePlanner,
        featureExpenses: featureExpenses ?? this.featureExpenses,
        viewOrdering: viewOrdering ?? this.viewOrdering,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        language,
        featurePlanner,
        featureExpenses,
        viewOrdering,
        member,
      ];

  @override
  String toString() {
    return name;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      "name": name,
    };
    if (image != null) {
      data['photo'] = image;
    }
    if (language != null) {
      data['language'] = language;
    }
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

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
