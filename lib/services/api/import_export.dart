import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  Future<void> importLanguage(String code) async {
    await get('/import/$code');
  }
}
