import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(Household household, String code) async {
    await get('${householdPath(household)}$baseRoute/$code');
  }
}
