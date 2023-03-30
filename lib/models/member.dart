import 'package:kitchenowl/models/user.dart';

class Member extends User {
  final bool owner;
  final bool admin;
  final double balance;

  const Member({
    required super.id,
    required super.name,
    required super.username,
    this.owner = false,
    super.serverAdmin = false,
    this.admin = false,
    this.balance = 0,
  });

  factory Member.fromJson(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      username: map['username'],
      name: map['name'],
      owner: map['owner'] ?? false,
      admin: map['admin'] ?? false,
      balance: map['expense_balance'] ?? 0,
    );
  }

  @override
  List<Object?> get props => super.props + [owner, admin, balance];

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
      };

  @override
  Map<String, dynamic> toJsonWithId() => {
        "id": id,
        "username": username,
        "name": name,
        "owner": owner,
        "admin": serverAdmin,
        "expense_balance": balance,
      };

  bool hasAdminRights() => super.hasServerAdminRights() || admin || owner;
}
