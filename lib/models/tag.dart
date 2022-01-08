import 'package:kitchenowl/models/model.dart';

class Tag extends Model {
  final int? id;
  final String name;

  const Tag({
    this.id,
    this.name = '',
  });

  factory Tag.fromJson(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
    );
  }

  Tag copyWith({
    String? name,
  }) =>
      Tag(
        id: id,
        name: name ?? this.name,
      );

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() {
    return name;
  }

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}
