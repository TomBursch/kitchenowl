import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/oidc_provider.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class ServerInfoCubit extends Cubit<ServerInfoState> {
  ServerInfoCubit() : super(const DisconnectedServerInfoState()) {
    ApiService.getInstance().addInfoListener(updateState);
  }

  void updateState() {
    Map<String, dynamic>? data = ApiService.getInstance().serverInfoMap;
    if (data == null) {
      emit(const DisconnectedServerInfoState());
    } else {
      emit(
        ConnectedServerInfoState.fromJson(
          data,
        ),
      );
    }
  }
}

abstract class ServerInfoState extends Equatable {
  const ServerInfoState();
}

class DisconnectedServerInfoState extends ServerInfoState {
  const DisconnectedServerInfoState();

  @override
  List<Object?> get props => [];
}

class ConnectedServerInfoState extends ServerInfoState {
  final int version;
  final int minFrontendVersion;
  final String? privacyPolicyUrl;
  final String? termsUrl;
  final bool openRegistration;
  final bool emailMandatory;
  final List<OIDCProivder> oidcProvider;

  const ConnectedServerInfoState({
    required this.version,
    required this.minFrontendVersion,
    this.privacyPolicyUrl,
    this.termsUrl,
    this.openRegistration = false,
    this.emailMandatory = false,
    this.oidcProvider = const [],
  });

  factory ConnectedServerInfoState.fromJson(Map<String, dynamic> data) {
    List<OIDCProivder> oidcProvider = const [];
    if (data.containsKey('oidc_provider')) {
      oidcProvider = List.from(data['oidc_provider']
          .map((e) => OIDCProivder.parse(e))
          .where((e) => e != null));
    }
    return ConnectedServerInfoState(
      version: data["version"],
      minFrontendVersion: data["min_frontend_version"],
      privacyPolicyUrl: data["privacy_policy"],
      termsUrl: data["terms"],
      openRegistration: data["open_registration"] ?? false,
      emailMandatory: data["email_mandatory"] ?? false,
      oidcProvider: oidcProvider,
    );
  }

  @override
  List<Object?> get props => [
        version,
        minFrontendVersion,
        privacyPolicyUrl,
        termsUrl,
        openRegistration,
        emailMandatory,
      ];
}
