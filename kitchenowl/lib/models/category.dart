import 'model.dart';

class Category extends Model {
  final int? id;
  final String name;
  final int ordering;

  const Category({this.id, this.name = "", this.ordering = 0});

  factory Category.fromJson(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'] ?? "",
        ordering: map['ordering'] ?? -1,
      );

  @override
  List<Object?> get props => [id, name, ordering];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "ordering": ordering,
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });

  Category copyWith({String? name, int? ordering}) => Category(
        id: id,
        name: name ?? this.name,
        ordering: ordering ?? this.ordering,
      );
}
