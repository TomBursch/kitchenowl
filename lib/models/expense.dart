import 'package:kitchenowl/models/model.dart';

class Expense extends Model {
  final int id;
  final String name;
  final double amount;
  final DateTime createdAt;
  final int paidById;
  final List<PaidForModel> paidFor;

  const Expense({
    this.id,
    this.name = '',
    this.amount = 0,
    this.paidById,
    this.paidFor = const [],
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> map) {
    List<PaidForModel> paidFor = const [];
    if (map.containsKey('paid_for')) {
      paidFor = List.from(map['paid_for'].map((e) => PaidForModel.fromJson(e)));
    }
    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      createdAt: null,
      paidById: map['paid_by_id'],
      paidFor: paidFor,
    );
  }

  Expense copyWith({
    String name,
    double amount,
    int paidById,
    List<PaidForModel> paidFor,
  }) =>
      Expense(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        paidById: paidById ?? this.paidById,
        paidFor: paidFor ?? this.paidFor,
      );

  @override
  List<Object> get props => [id, name, amount, paidById] + paidFor;

  @override
  Map<String, dynamic> toJson() => {
        "name": name,
        "amount": amount,
        "paid_by": {"id": paidById},
        "paid_for": paidFor.map((e) => e.toJsonWithId()).toList()
      };

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}

class PaidForModel extends Model {
  final int userId;
  final int factor;

  PaidForModel({this.userId, this.factor});

  @override
  List<Object> get props => [userId, factor];

  @override
  Map<String, dynamic> toJson() => {
        "user": {"id": userId},
        "factor": factor,
      };

  factory PaidForModel.fromJson(Map<String, dynamic> map) {
    return PaidForModel(
      userId: map['user_id'],
      factor: map['factor'],
    );
  }
}
