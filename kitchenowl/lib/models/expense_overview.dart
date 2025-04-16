import 'package:intl/intl.dart';
import 'package:kitchenowl/enums/timeframe.dart';
import 'package:kitchenowl/models/model.dart';

class ExpenseOverview extends Model {
  final Timeframe timeframe;
  final Map<int, double> byCategory;
  final Map<DateTime, double> bySubTimeframe;

  const ExpenseOverview({
    this.timeframe = Timeframe.monthly,
    this.byCategory = const {},
    this.bySubTimeframe = const {},
  });

  factory ExpenseOverview.fromJson(
    Timeframe timeframe,
    Map<String, dynamic> map,
  ) {
    return ExpenseOverview(
      timeframe: timeframe,
      byCategory: Map.from(map["by_category"])
          .map((key, value) => MapEntry(int.parse(key), value)),
      bySubTimeframe: Map.from(map["by_subframe"]).map((key, value) => MapEntry(
          timeframe != Timeframe.yearly
              ? DateTime.parse(key)
              : DateFormat("yyyy-mm").parse(key),
          value)),
    );
  }

  double getTotalForPeriod() {
    return byCategory.isEmpty ? 0 : byCategory.values.reduce((v, e) => v + e);
  }

  double getExpenseTotalForPeriod() {
    return byCategory.values.where((v) => v > 0).fold(0.0, (sum, e) => sum + e);
  }

  double getIncomeTotalForPeriod() {
    return byCategory.values.where((v) => v < 0).fold(0.0, (sum, e) => sum + e);
  }

  @override
  List<Object?> get props => [timeframe, byCategory, bySubTimeframe];

  @override
  Map<String, dynamic> toJson() => {};
}
