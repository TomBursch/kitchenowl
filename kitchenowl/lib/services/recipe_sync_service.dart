import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/storage/storage.dart';

/// Incrementally syncs full recipe details from the delta-sync endpoint.
/// Only active on mobile (not web). Runs in the background after the slim
/// list has been rendered so the UI stays responsive.
class RecipeSyncService {
  static RecipeSyncService? _instance;

  RecipeSyncService._internal();
  static RecipeSyncService getInstance() {
    _instance ??= RecipeSyncService._internal();
    return _instance!;
  }

  static String _cursorKey(Household household) =>
      'recipe_sync_cursor_${household.id}';

  Future<int> _readCursor(Household household) async {
    final val = await PreferenceStorage.getInstance()
        .readInt(key: _cursorKey(household));
    return val ?? 0;
  }

  Future<void> _writeCursor(Household household, int timestamp) async {
    await PreferenceStorage.getInstance()
        .writeInt(key: _cursorKey(household), value: timestamp);
  }

  /// Trigger an incremental background sync for [household].
  /// Does nothing on web.
  Future<void> sync(Household household) async {
    if (kIsWeb) return;

    try {
      final cursor = await _readCursor(household);
      int page = 0;
      bool hasMore = true;
      // Server timestamp from the first page response — used as new cursor to
      // avoid client-clock skew dropping updates written between pages.
      int? serverTimestamp;

      // Load existing cached list to upsert into
      final existing =
          await MemStorage.getInstance().readRecipes(household) ?? [];
      final byId = <int, Recipe>{
        for (final r in existing)
          if (r.id != null) r.id!: r,
      };

      while (hasMore) {
        final result = await ApiService.getInstance().getRecipesDeltaSync(
          household,
          updatedAfter: cursor,
          page: page,
          perPage: 50,
        );
        if (result == null) break;

        serverTimestamp ??= result.serverTime;

        for (final r in result.recipes) {
          if (r.id != null) byId[r.id!] = r;
        }
        for (final deletedId in result.deletedIds) {
          byId.remove(deletedId);
        }

        hasMore = result.hasMore;
        page++;
      }

      final merged = byId.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      await MemStorage.getInstance().writeRecipes(household, merged);
      // Persist the server-provided timestamp to avoid client-clock skew.
      if (serverTimestamp != null) {
        await _writeCursor(household, serverTimestamp!);
      }
    } catch (_) {
      // Background sync errors are non-fatal; the UI continues with cached data.
    }
  }
}
