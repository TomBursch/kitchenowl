import 'package:kitchenowl/enums/token_type_enum.dart';
import 'package:kitchenowl/models/model.dart';

class Token extends Model {
  final int id;
  final String name;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final TokenTypeEnum type;

  const Token({
    required this.id,
    this.name = '',
    required this.type,
    this.createdAt,
    this.lastUsedAt,
  });

  factory Token.fromJson(Map<String, dynamic> map) {
    final TokenTypeEnum type;
    if (map['type'] == 'refresh') {
      type = TokenTypeEnum.refresh;
    } else if (map['type'] == 'llt') {
      type = TokenTypeEnum.longlived;
    } else {
      type = TokenTypeEnum.access;
    }

    DateTime? createdAt;
    if (map.containsKey('created_at') && map['created_at'] != null) {
      createdAt =
          DateTime.fromMillisecondsSinceEpoch(map['created_at'], isUtc: true)
              .toLocal();
    }

    DateTime? lastUsedAt;
    if (map.containsKey('last_used_at') && map['last_used_at'] != null) {
      lastUsedAt =
          DateTime.fromMillisecondsSinceEpoch(map['last_used_at'], isUtc: true)
              .toLocal();
    }

    return Token(
      id: map['id'],
      name: map['name'],
      type: type,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
    );
  }

  Token copyWith({
    String? name,
  }) =>
      Token(
        id: id,
        name: name ?? this.name,
        type: type,
        createdAt: createdAt,
        lastUsedAt: lastUsedAt,
      );

  @override
  List<Object?> get props => [id, name, type, createdAt, lastUsedAt];

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
