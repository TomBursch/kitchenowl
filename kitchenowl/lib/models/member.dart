import 'package:kitchenowl/models/user.dart';

class Member extends User {
  final bool owner;
  final bool admin;
  final double balance;

  const Member({
    required super.id,
    required super.name,
    required super.username,
    super.image,
    this.owner = false,
    super.serverAdmin = false,
    this.admin = true,
    this.balance = 0,
  });

  factory Member.fromUser(
    User user, {
    bool admin = true,
  }) {
    return Member(
      id: user.id,
      name: user.name,
      username: user.username,
      admin: admin,
    );
  }

  factory Member.fromJson(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      username: map['username'],
      name: map['name'],
      image: map['photo'],
      owner: map['owner'] ?? false,
      admin: map['admin'] ?? true,
      balance:
          ((map['expense_balance'] as double? ?? 0) * 100).round().toDouble() /
              100,
    );
  }

  @override
  List<Object?> get props => super.props + [owner, admin, balance];

  @override
  Map<String, dynamic> toJson() => {
        "admin": admin,
      };

  @override
  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "username": username,
        "name": name,
        "owner": owner,
        "admin": admin || serverAdmin,
        "expense_balance": balance,
      };

  Member copyWith({
    String? name,
    String? image,
    bool? admin,
  }) =>
      Member(
        id: id,
        name: name ?? this.name,
        image: image ?? this.image,
        username: username,
        admin: admin ?? this.admin,
        balance: balance,
        owner: owner,
        serverAdmin: serverAdmin,
      );

  bool hasAdminRights() => super.hasServerAdminRights() || admin || owner;
}
