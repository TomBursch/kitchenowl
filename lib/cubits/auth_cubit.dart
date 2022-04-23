import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kitchenowl/models/server_settings.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const Loading()) {
    ApiService.getInstance().addListener(updateState);
    setup();
  }

  void setup() async {
    String? url;
    url = kIsWeb
        ? dotenv.env['FRONT_URL'] ?? "http://localhost"
        : await PreferenceStorage.getInstance().read(key: 'URL');
    if (url != null && url.isNotEmpty) {
      final token = await SecureStorage.getInstance().read(key: 'TOKEN');
      _newConnection(url, token: token, storeData: false);
    } else {
      refresh();
    }
  }

  void updateState() async {
    switch (ApiService.getInstance().connectionStatus) {
      case Connection.authenticated:
        final user = (await ApiService.getInstance().getUser())!;
        await TempStorage.getInstance().writeUser(user);
        await TransactionHandler.getInstance().runOpenTransactions();
        emit(Authenticated(user));
        break;
      case Connection.disconnected:
        if (kIsWeb || ApiService.getInstance().baseUrl.isNotEmpty) {
          final user = await TempStorage.getInstance().readUser();
          if (user != null) {
            emit(AuthenticatedOffline(user));
          } else {
            emit(const Unreachable());
          }
        } else {
          emit(const Setup());
        }
        break;
      case Connection.connected:
        if (await ApiService.getInstance().isOnboarding()) {
          emit(const Onboarding());
        } else {
          emit(const Unauthenticated());
        }
        break;
      case Connection.unsupported:
        emit(const Unsupported());
        break;
      case Connection.undefined:
        emit(const Loading());
        break;
    }
  }

  void setupServer(String url) async {
    if (kIsWeb) return;
    emit(const Loading());
    _newConnection(url);
  }

  User? getUser() {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }

    return null;
  }

  Future<void> refresh() => ApiService.getInstance().refresh();

  Future<void> refreshUser() async {
    if (state is Authenticated) {
      if (state is AuthenticatedOffline) {
        final user = await TempStorage.getInstance().readUser();
        if (user != null) {
          emit(AuthenticatedOffline(user));
        } else {
          emit(const Unreachable());
        }
      } else {
        emit(Authenticated((await ApiService.getInstance().getUser())!));
      }
    }
  }

  // ignore: long-parameter-list
  void onboard({
    required String username,
    required String name,
    required String password,
    ServerSettings? settings,
    String? language,
  }) async {
    emit(const Loading());
    if (await ApiService.getInstance().isOnboarding()) {
      final token = await ApiService.getInstance()
          .onboarding(username, name, password, settings, language);
      if (token != null && ApiService.getInstance().isAuthenticated()) {
        await SecureStorage.getInstance().write(key: 'TOKEN', value: token);
      } else {
        updateState();
      }
    }
  }

  void login(String username, String password) async {
    emit(const Loading());
    final token = await ApiService.getInstance().login(username, password);
    if (token != null && ApiService.getInstance().isAuthenticated()) {
      await SecureStorage.getInstance().write(key: 'TOKEN', value: token);
    } else {
      updateState();
    }
  }

  void logout() async {
    emit(const Loading());
    await SecureStorage.getInstance().delete(key: 'TOKEN');
    await TempStorage.getInstance().clearAll();
    ApiService.getInstance().refreshToken = '';
    if (ApiService.getInstance().connectionStatus == Connection.disconnected) {
      emit(const Unreachable());
    }
    refresh();
  }

  void removeServer() async {
    if (kIsWeb) return logout(); //Cannot remove server on WEB

    emit(const Loading());
    await PreferenceStorage.getInstance().delete(key: 'URL');
    await SecureStorage.getInstance().delete(key: 'TOKEN');
    await TempStorage.getInstance().clearAll();
    ApiService.getInstance().dispose();
    refresh();
  }

  Future<void> _newConnection(
    String? url, {
    String? token,
    bool storeData = true,
  }) async {
    if (url == null || url.isEmpty) return;
    await ApiService.connectTo(url, refreshToken: token);
    if (storeData && ApiService.getInstance().isConnected()) {
      if (!kIsWeb) {
        await PreferenceStorage.getInstance().write(key: 'URL', value: url);
      }
      if (token != null && token.isNotEmpty) {
        await SecureStorage.getInstance().write(key: 'TOKEN', value: token);
      }
    }
  }
}

abstract class AuthState extends Equatable {
  final int orderId; // used by the ui

  const AuthState(this.orderId);
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user) : super(3);

  @override
  List<Object?> get props => [user];
}

class AuthenticatedOffline extends Authenticated {
  const AuthenticatedOffline(User user) : super(user);

  @override
  List<Object?> get props => [user];
}

class Onboarding extends AuthState {
  const Onboarding() : super(1);

  @override
  List<Object?> get props => ["Onboarding"];
}

class Unauthenticated extends AuthState {
  const Unauthenticated() : super(2);

  @override
  List<Object?> get props => ["Setup"];
}

class Setup extends AuthState {
  const Setup() : super(0);

  @override
  List<Object?> get props => ["Unauthenticated"];
}

class Loading extends AuthState {
  const Loading() : super(3);

  @override
  List<Object?> get props => ["Initial"];
}

class Unreachable extends AuthState {
  const Unreachable() : super(4);

  @override
  List<Object?> get props => ["Unreachable"];
}

class Unsupported extends AuthState {
  const Unsupported() : super(5);

  @override
  List<Object?> get props => ["Unsupported"];
}
