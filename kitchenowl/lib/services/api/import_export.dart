import 'dart:convert';

import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe_import_preview.dart';
import 'package:kitchenowl/models/recipe_import_result.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(Household household, String code) async {
    await get('${householdPath(household)}$baseRoute/$code');
  }

  Future<void> importHousehold(
    Household household,
    Map<String, dynamic> content, [
    bool overwriteRecipes = false,
  ]) async {
    content["recipe_overwrite"] = overwriteRecipes;
    await post(
      '${householdPath(household)}$baseRoute',
      jsonEncode(content),
      timeout: const Duration(minutes: 5),
    );
  }

  Future<String?> exportHousehold(Household household) async {
    final res = await get('${householdPath(household)}/export');
    if (res.statusCode != 200) return null;

    return res.body;
  }

  Future<RecipeImportPreview?> previewRecipeImport(
    Household household,
    NamedByteArray file,
  ) async {
    final res = await postBytes(
      '${householdPath(household)}$baseRoute/recipes/preview',
      file,
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    return RecipeImportPreview.fromJson(body);
  }

  Future<RecipeImportResult?> commitRecipeImport(
    Household household,
    String token,
    Map<String, String> decisions,
  ) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/recipes/commit',
      jsonEncode({
        'token': token,
        'decisions': decisions,
      }),
    );
    if (res.statusCode != 200) return null;

    return RecipeImportResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<RecipeImportResult?> getRecipeImportStatus(
    Household household,
    String token,
  ) async {
    final res = await get('${householdPath(household)}$baseRoute/recipes/commit/$token');
    if (res.statusCode != 200) return null;

    return RecipeImportResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
