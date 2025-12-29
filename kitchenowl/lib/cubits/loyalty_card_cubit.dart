import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class LoyaltyCardCubit extends Cubit<LoyaltyCardState> {
  LoyaltyCardCubit(LoyaltyCard loyaltyCard)
      : super(LoyaltyCardState(loyaltyCard: loyaltyCard)) {
    refresh();
  }

  Future<void> refresh() async {
    if (state.loyaltyCard.id == null) return;

    final card = await ApiService.getInstance().getLoyaltyCard(state.loyaltyCard);
    if (card != null) {
      emit(LoyaltyCardState(loyaltyCard: card));
    }
  }

  void updateCard(LoyaltyCard loyaltyCard) {
    emit(LoyaltyCardState(loyaltyCard: loyaltyCard));
  }

  Future<bool> deleteCard() async {
    if (state.loyaltyCard.id == null) return false;
    return await ApiService.getInstance().deleteLoyaltyCard(state.loyaltyCard);
  }
}

class LoyaltyCardState extends Equatable {
  final LoyaltyCard loyaltyCard;

  const LoyaltyCardState({required this.loyaltyCard});

  @override
  List<Object?> get props => [loyaltyCard];
}

