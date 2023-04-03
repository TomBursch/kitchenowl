import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class UserSearchCubit extends Cubit<UserSearchState> {
  UserSearchCubit() : super(const UserSearchState());

  Future<void> search(String query) async {
    if (query.isNotEmpty) {
      emit(UserSearchState(
        query: query,
        searchResult: await ApiService.getInstance().searchUser(query) ?? [],
      ));
    } else {
      emit(UserSearchState(query: query, searchResult: state.searchResult));
    }
  }
}

class UserSearchState extends Equatable {
  final String query;
  final List<User> searchResult;

  const UserSearchState({this.query = "", this.searchResult = const []});

  @override
  List<Object?> get props => [query, searchResult];
}
