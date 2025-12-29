import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionLoyaltyCardGetAll extends Transaction<List<LoyaltyCard>> {
  final Household household;

  TransactionLoyaltyCardGetAll({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
            timestamp ?? DateTime.now(), "TransactionLoyaltyCardGetAll");

  @override
  Future<List<LoyaltyCard>> runLocal() async {
    return [];
  }

  @override
  Future<List<LoyaltyCard>?> runOnline() async {
    return await ApiService.getInstance().getAllLoyaltyCards(
      household: household,
    );
  }
}

class TransactionLoyaltyCardGet extends Transaction<LoyaltyCard> {
  final LoyaltyCard loyaltyCard;

  TransactionLoyaltyCardGet({required this.loyaltyCard, DateTime? timestamp})
      : super.internal(
            timestamp ?? DateTime.now(), "TransactionLoyaltyCardGet");

  @override
  Future<LoyaltyCard> runLocal() async {
    return loyaltyCard;
  }

  @override
  Future<LoyaltyCard?> runOnline() async {
    return await ApiService.getInstance().getLoyaltyCard(loyaltyCard);
  }
}

class TransactionLoyaltyCardAdd extends Transaction<LoyaltyCard?> {
  final LoyaltyCard loyaltyCard;
  final Household household;

  TransactionLoyaltyCardAdd({
    required this.household,
    required this.loyaltyCard,
    DateTime? timestamp,
  }) : super.internal(
            timestamp ?? DateTime.now(), "TransactionLoyaltyCardAdd");

  @override
  Future<LoyaltyCard?> runLocal() async {
    return loyaltyCard;
  }

  @override
  Future<LoyaltyCard?> runOnline() {
    return ApiService.getInstance().addLoyaltyCard(household, loyaltyCard);
  }
}

class TransactionLoyaltyCardRemove extends Transaction<bool> {
  final LoyaltyCard loyaltyCard;

  TransactionLoyaltyCardRemove({required this.loyaltyCard, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionLoyaltyCardRemove",
        );

  factory TransactionLoyaltyCardRemove.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionLoyaltyCardRemove(
        loyaltyCard: LoyaltyCard.fromJson(map['loyalty_card']),
        timestamp: timestamp,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "loyalty_card": loyaltyCard.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().deleteLoyaltyCard(loyaltyCard);
  }
}

class TransactionLoyaltyCardUpdate extends Transaction<bool> {
  final LoyaltyCard loyaltyCard;

  TransactionLoyaltyCardUpdate({required this.loyaltyCard, DateTime? timestamp})
      : super.internal(
            timestamp ?? DateTime.now(), "TransactionLoyaltyCardUpdate");

  factory TransactionLoyaltyCardUpdate.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionLoyaltyCardUpdate(
        loyaltyCard: LoyaltyCard.fromJson(map['loyalty_card']),
        timestamp: timestamp,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "loyalty_card": loyaltyCard.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().updateLoyaltyCard(loyaltyCard);
  }
}

