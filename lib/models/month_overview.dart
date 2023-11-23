import 'package:kitchenowl/models/model.dart';

class ExpenseOverview extends Model {
  final Map<int, double> byCategory;
  final Map<DateTime, double> byDay;

  const ExpenseOverview({this.byCategory = const {}, this.byDay = const {}});

  factory ExpenseOverview.fromJson(Map<String, dynamic> map) {
    return ExpenseOverview(
      byCategory: Map.from(map["by_category"])
          .map((key, value) => MapEntry(int.parse(key), value)),
      byDay: Map.from(map["by_day"])
          .map((key, value) => MapEntry(DateTime.parse(key), value)),
    );
  }

  double getTotalForPeriod() {
    return byCategory.values.reduce((v, e) => v + e);
  }

  @override
  List<Object?> get props => [byCategory, byDay];

  @override
  Map<String, dynamic> toJson() => {};
}
