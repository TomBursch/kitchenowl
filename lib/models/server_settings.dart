import 'model.dart';

class ServerSettings extends Model {
  const ServerSettings();

  factory ServerSettings.fromJson(Map<String, dynamic> map) {
    return const ServerSettings();
  }

  @override
  List<Object?> get props => [];

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    return data;
  }

  ServerSettings copyWith() => const ServerSettings();

  ServerSettings copyFrom(ServerSettings serverSettings) =>
      const ServerSettings();
}
