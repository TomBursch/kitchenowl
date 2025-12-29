import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/loyalty_card.dart';

class LoyaltyCardListCubit extends Cubit<LoyaltyCardListCubitState> {
  final Household household;
  Future<void>? _refreshThread;

  LoyaltyCardListCubit(this.household)
      : super(const LoadingLoyaltyCardListCubitState()) {
    refresh();
  }

  Future<void> remove(LoyaltyCard loyaltyCard) async {
    await TransactionHandler.getInstance().runTransaction(
      TransactionLoyaltyCardRemove(loyaltyCard: loyaltyCard),
    );
    await refresh();
  }

  Future<LoyaltyCard?> add(LoyaltyCard loyaltyCard) async {
    final result = await TransactionHandler.getInstance().runTransaction(
      TransactionLoyaltyCardAdd(
        household: household,
        loyaltyCard: loyaltyCard,
      ),
    );
    await refresh();
    return result;
  }

  Future<void> update(LoyaltyCard loyaltyCard) async {
    await TransactionHandler.getInstance().runTransaction(
      TransactionLoyaltyCardUpdate(loyaltyCard: loyaltyCard),
    );
    await refresh();
  }

  Future<void> refresh() {
    _refreshThread ??= _refresh();

    return _refreshThread!;
  }

  Future<void> _refresh() async {
    final loyaltyCards = await TransactionHandler.getInstance().runTransaction(
      TransactionLoyaltyCardGetAll(household: household),
    );

    emit(LoyaltyCardListCubitState(
      loyaltyCards: loyaltyCards,
    ));
    _refreshThread = null;
  }
}

class LoyaltyCardListCubitState extends Equatable {
  final List<LoyaltyCard> loyaltyCards;

  const LoyaltyCardListCubitState({
    this.loyaltyCards = const [],
  });

  LoyaltyCardListCubitState copyWith({
    List<LoyaltyCard>? loyaltyCards,
  }) =>
      LoyaltyCardListCubitState(
        loyaltyCards: loyaltyCards ?? this.loyaltyCards,
      );

  @override
  List<Object?> get props => loyaltyCards;
}

class LoadingLoyaltyCardListCubitState extends LoyaltyCardListCubitState {
  const LoadingLoyaltyCardListCubitState() : super();

  @override
  LoyaltyCardListCubitState copyWith({
    List<LoyaltyCard>? loyaltyCards,
  }) =>
      LoadingLoyaltyCardListCubitState();
}

