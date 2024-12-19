import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/member.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class HouseholdMemberCubit extends Cubit<HouseholdMemberState> {
  final Household household;

  HouseholdMemberCubit(this.household)
      : super(HouseholdMemberState(
          member: household.member ?? const [],
        )) {
    refresh();
  }

  Future<void> refresh() async {
    Future<Household?> fHousehold =
        TransactionHandler.getInstance().runTransaction(
      TransactionHouseholdGet(household: this.household),
    );

    Household household = await fHousehold ?? this.household;

    emit(HouseholdMemberState(
      member: household.member ?? this.household.member ?? const [],
    ));
  }

  Future<void> removeMember(Member member) {
    return ApiService.getInstance()
        .removeHouseholdMember(household, member)
        .then((value) => refresh());
  }

  Future<void> putMember(Member member) {
    return ApiService.getInstance()
        .putHouseholdMember(household, member)
        .then((value) => refresh());
  }
}

class HouseholdMemberState extends Equatable {
  final List<Member> member;

  const HouseholdMemberState({
    this.member = const [],
  });

  HouseholdMemberState copyWith({
    List<Member>? member,
  }) =>
      HouseholdMemberState(
        member: member ?? this.member,
      );

  @override
  List<Object?> get props => member;
}
