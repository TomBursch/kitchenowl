import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(String code) async {
    await get(baseRoute + '/$code');
  }
}
