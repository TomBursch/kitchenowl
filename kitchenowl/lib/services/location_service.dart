import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kitchenowl/gen/l10n/app_localizations.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/background_task.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:native_geofence/native_geofence.dart' as ng;
import 'package:shared_preferences/shared_preferences.dart';

/// A request to open a specific shopping list, e.g. after tapping an arrival
/// notification.
class ShoppingListRequest {
  final int householdId;
  final int shoppingListId;

  const ShoppingListRequest(this.householdId, this.shoppingListId);
}

/// Device local settings for location based shopping lists.
class ShoppingListLocationSettings extends Equatable {
  final bool enabled;
  final bool notify;
  final bool notifyOncePerVisit;
  final bool ignoreEmptyLists;
  final bool autoSwitch;
  final bool confirmSwitch;
  final Set<int> mutedShoppingLists;

  const ShoppingListLocationSettings({
    this.enabled = false,
    this.notify = true,
    this.notifyOncePerVisit = true,
    this.ignoreEmptyLists = true,
    this.autoSwitch = false,
    this.confirmSwitch = true,
    this.mutedShoppingLists = const {},
  });

  ShoppingListLocationSettings copyWith({
    bool? enabled,
    bool? notify,
    bool? notifyOncePerVisit,
    bool? ignoreEmptyLists,
    bool? autoSwitch,
    bool? confirmSwitch,
    Set<int>? mutedShoppingLists,
  }) =>
      ShoppingListLocationSettings(
        enabled: enabled ?? this.enabled,
        notify: notify ?? this.notify,
        notifyOncePerVisit: notifyOncePerVisit ?? this.notifyOncePerVisit,
        ignoreEmptyLists: ignoreEmptyLists ?? this.ignoreEmptyLists,
        autoSwitch: autoSwitch ?? this.autoSwitch,
        confirmSwitch: confirmSwitch ?? this.confirmSwitch,
        mutedShoppingLists: mutedShoppingLists ?? this.mutedShoppingLists,
      );

  @override
  List<Object?> get props => [
        enabled,
        notify,
        notifyOncePerVisit,
        ignoreEmptyLists,
        autoSwitch,
        confirmSwitch,
        mutedShoppingLists,
      ];
}

/// Handles everything around shopping list locations: permissions,
/// registering geofences with the OS, arrival notifications and finding the
/// shopping list for the current position.
class LocationService {
  static const prefEnabled = 'locationEnabled';
  static const prefNotify = 'locationNotify';
  static const prefNotifyOncePerVisit = 'locationNotifyOncePerVisit';
  static const prefIgnoreEmptyLists = 'locationIgnoreEmptyLists';
  static const prefAutoSwitch = 'locationAutoSwitch';
  static const prefConfirmSwitch = 'locationConfirmSwitch';
  static const prefMutedShoppingLists = 'locationMutedShoppingLists';
  static const _prefLastNotified = 'locationLastNotified';

  static const _geofencePrefix = 'kitchenowl';
  static const _notificationChannelId = 'shoppinglist_location';
  // iOS can monitor at most 20 regions per app, Android 100
  static const _iosMaxGeofences = 20;
  static const _androidMaxGeofences = 100;
  static const _visitDuration = Duration(hours: 2);

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;
  static String? _lastSyncSignature;

  /// Set when a shopping list should be opened, e.g. after tapping a
  /// notification. Consumers should reset it to null after handling.
  static final ValueNotifier<ShoppingListRequest?> requestedShoppingList =
      ValueNotifier(null);

  /// Whether the current position can be determined on this platform
  static bool get isLocationSupported =>
      kIsWeb || Platform.isAndroid || Platform.isIOS;

  /// Whether background geofencing and notifications are supported
  static bool get isGeofencingSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<ShoppingListLocationSettings> readSettings(
      {bool reload = false}) async {
    if (reload) await (await SharedPreferences.getInstance()).reload();
    final prefs = PreferenceStorage.getInstance();
    return ShoppingListLocationSettings(
      enabled: await prefs.readBool(key: prefEnabled) ?? false,
      notify: await prefs.readBool(key: prefNotify) ?? true,
      notifyOncePerVisit:
          await prefs.readBool(key: prefNotifyOncePerVisit) ?? true,
      ignoreEmptyLists: await prefs.readBool(key: prefIgnoreEmptyLists) ?? true,
      autoSwitch: await prefs.readBool(key: prefAutoSwitch) ?? false,
      confirmSwitch: await prefs.readBool(key: prefConfirmSwitch) ?? true,
      mutedShoppingLists: _parseIdSet(
        await prefs.read(key: prefMutedShoppingLists),
      ),
    );
  }

  static Future<void> setShoppingListMuted(
      int shoppingListId, bool muted) async {
    final settings = await readSettings();
    final ids = Set.of(settings.mutedShoppingLists);
    muted ? ids.add(shoppingListId) : ids.remove(shoppingListId);
    await PreferenceStorage.getInstance()
        .write(key: prefMutedShoppingLists, value: ids.join(','));
    _lastSyncSignature = null;
  }

  static Set<int> _parseIdSet(String? value) =>
      (value ?? '').split(',').map(int.tryParse).nonNulls.toSet();

  /// Requests the location permission. With [background] the user is
  /// additionally asked for background access, which geofencing requires.
  static Future<bool> requestPermission({bool background = false}) async {
    if (!isLocationSupported) return false;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return false;
      }
      if (background &&
          isGeofencingSupported &&
          permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }

      return true;
    } catch (e) {
      debugPrint('Location permission request failed: $e');
      return false;
    }
  }

  static Future<bool> hasBackgroundPermission() async {
    if (!isGeofencingSupported) return false;
    return await Geolocator.checkPermission() == LocationPermission.always;
  }

  static Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  static Future<bool> requestNotificationPermission() async {
    if (!isGeofencingSupported) return false;
    await _initNotifications();
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  /// Returns the current position or null if it cannot be determined.
  /// Never asks the user for permission unless [requestPermission] is set.
  static Future<Position?> getCurrentPosition({
    bool requestPermission = false,
  }) async {
    if (!isLocationSupported) return null;
    try {
      if (requestPermission) {
        if (!await LocationService.requestPermission()) return null;
      } else {
        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      debugPrint('Could not determine location: $e');
      return null;
    }
  }

  /// Finds the shopping list with a location containing the given position.
  /// If multiple match, the closest location wins.
  static (ShoppingList, ShoppingListLocation)? findShoppingListAt(
    Iterable<ShoppingList> shoppingLists,
    double latitude,
    double longitude,
  ) {
    (ShoppingList, ShoppingListLocation)? res;
    double? resDistance;
    for (final list in shoppingLists) {
      for (final location in list.locations) {
        final distance = location.distanceTo(latitude, longitude);
        if (distance <= location.radius &&
            (resDistance == null || distance < resDistance)) {
          res = (list, location);
          resDistance = distance;
        }
      }
    }

    return res;
  }

  /// Initializes notifications and handles taps on arrival notifications.
  /// Should be called once on app start.
  static Future<void> initialize() async {
    if (!isGeofencingSupported) return;
    await _initNotifications(onTap: _handleNotificationPayload);
    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  static void _handleNotificationPayload(String? payload) {
    final parts = (payload ?? '').split(':').map(int.tryParse).toList();
    if (parts.length != 2 || parts.contains(null)) return;
    requestedShoppingList.value = ShoppingListRequest(parts[0]!, parts[1]!);
  }

  static Future<void> _initNotifications({
    void Function(String? payload)? onTap,
  }) async {
    if (_notificationsInitialized && onTap == null) return;
    await _notifications.initialize(
      settings: const InitializationSettings(
        android:
            AndroidInitializationSettings('@mipmap/ic_launcher_monochrome'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse:
          onTap != null ? (response) => onTap(response.payload) : null,
    );
    _notificationsInitialized = true;
  }

  /// Registers the locations of the given shopping lists as geofences.
  /// Geofences of other households and removed locations are unregistered.
  static Future<void> syncGeofences(
    Household household,
    Iterable<ShoppingList> shoppingLists, {
    bool force = false,
  }) async {
    if (!isGeofencingSupported) return;
    try {
      final settings = await readSettings();
      final desired = <String, ng.Geofence>{};
      if (settings.enabled && settings.notify) {
        final maxGeofences =
            Platform.isIOS ? _iosMaxGeofences : _androidMaxGeofences;
        for (final list in shoppingLists) {
          if (list.id == null ||
              settings.mutedShoppingLists.contains(list.id)) {
            continue;
          }
          list.locations.forEachIndexed((i, location) {
            if (desired.length >= maxGeofences) return;
            final id = '$_geofencePrefix:${household.id}:${list.id}:$i';
            desired[id] = ng.Geofence(
              id: id,
              location: ng.Location(
                latitude: location.latitude,
                longitude: location.longitude,
              ),
              radiusMeters: location.radius.toDouble(),
              triggers: const {ng.GeofenceEvent.enter},
              iosSettings: const ng.IosGeofenceSettings(initialTrigger: false),
              androidSettings: const ng.AndroidGeofenceSettings(
                initialTriggers: {},
                notificationResponsiveness: Duration(minutes: 1),
              ),
            );
          });
        }
      }

      final signature = desired.values
          .map((e) =>
              '${e.id}@${e.location.latitude},${e.location.longitude},${e.radiusMeters}')
          .join(';');
      if (!force && signature == _lastSyncSignature) return;

      final manager = ng.NativeGeofenceManager.instance;
      await manager.initialize();
      final registered = await manager.getRegisteredGeofences();
      for (final geofence in registered) {
        if (!geofence.id.startsWith('$_geofencePrefix:')) continue;
        final target = desired[geofence.id];
        if (target == null ||
            target.location.latitude != geofence.location.latitude ||
            target.location.longitude != geofence.location.longitude ||
            target.radiusMeters != geofence.radiusMeters) {
          await manager.removeGeofenceById(geofence.id);
        } else {
          desired.remove(geofence.id);
        }
      }
      for (final geofence in desired.values) {
        await manager.createGeofence(geofence, shoppingListGeofenceTriggered);
      }
      _lastSyncSignature = signature;
    } on ng.NativeGeofenceException catch (e) {
      debugPrint('Could not sync geofences: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Could not sync geofences: $e');
    }
  }

  /// Re-syncs the geofences of the last opened household from the cache.
  static Future<void> syncGeofencesFromCache() async {
    if (!isGeofencingSupported) return;
    final householdId =
        await PreferenceStorage.getInstance().readInt(key: 'lastHouseholdId');
    if (householdId == null) return removeAllGeofences();
    final household = Household(id: householdId);
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household);
    if (shoppingLists == null) return;
    await syncGeofences(household, shoppingLists, force: true);
  }

  static Future<void> removeAllGeofences() async {
    if (!isGeofencingSupported) return;
    _lastSyncSignature = null;
    try {
      final manager = ng.NativeGeofenceManager.instance;
      await manager.initialize();
      for (final id in await manager.getRegisteredGeofenceIds()) {
        if (id.startsWith('$_geofencePrefix:')) {
          await manager.removeGeofenceById(id);
        }
      }
    } catch (e) {
      debugPrint('Could not remove geofences: $e');
    }
  }

  /// Handles a geofence event in a (possibly headless) background isolate.
  static Future<void> handleGeofenceEvent(
    ng.GeofenceCallbackParams params,
  ) async {
    if (params.event != ng.GeofenceEvent.enter) return;
    final settings = await readSettings(reload: true);
    if (!settings.enabled || !settings.notify) return;

    // household id -> (shopping list id -> location index)
    final triggered = <int, Map<int, int>>{};
    for (final geofence in params.geofences) {
      final parts = geofence.id.split(':');
      if (parts.length != 4 || parts[0] != _geofencePrefix) continue;
      final householdId = int.tryParse(parts[1]);
      final listId = int.tryParse(parts[2]);
      final index = int.tryParse(parts[3]);
      if (householdId == null || listId == null || index == null) continue;
      if (settings.mutedShoppingLists.contains(listId)) continue;
      triggered.putIfAbsent(householdId, () => {})[listId] ??= index;
    }
    if (triggered.isEmpty) return;

    final prefs = PreferenceStorage.getInstance();
    final Map<String, dynamic> lastNotified =
        jsonDecode(await prefs.read(key: _prefLastNotified) ?? '{}');
    final now = DateTime.now();
    if (settings.notifyOncePerVisit) {
      triggered.forEach((_, lists) => lists.removeWhere((listId, _) {
            final last = lastNotified['$listId'];
            return last is int &&
                now.difference(DateTime.fromMillisecondsSinceEpoch(last)) <
                    _visitDuration;
          }));
      triggered.removeWhere((_, lists) => lists.isEmpty);
      if (triggered.isEmpty) return;
    }

    final online = await BackgroundTask.connectHeadless()
        .timeout(const Duration(seconds: 20), onTimeout: () => false)
        .catchError((_) => false);

    final l10n = _lookupLocalizations();
    await _initNotifications();
    for (final entry in triggered.entries) {
      final household = Household(id: entry.key);
      List<ShoppingList>? shoppingLists;
      if (online) {
        shoppingLists = await ApiService.getInstance()
            .getShoppingLists(household)
            .timeout(const Duration(seconds: 20), onTimeout: () => null)
            .catchError((_) => null);
        if (shoppingLists != null) {
          await MemStorage.getInstance()
              .writeShoppingLists(household, shoppingLists);
        }
      }
      shoppingLists ??= await MemStorage.getInstance()
          .readShoppingLists(household)
          .catchError((_) => null);
      if (shoppingLists == null) continue;

      for (final listEntry in entry.value.entries) {
        final list = shoppingLists.firstWhereOrNull(
          (e) => e.id == listEntry.key,
        );
        if (list == null) continue;
        if (list.items.isEmpty && settings.ignoreEmptyLists) continue;

        final location = list.locations.elementAtOrNull(listEntry.value);
        final place =
            (location?.name?.isNotEmpty ?? false) ? location!.name! : list.name;
        await _notifications.show(
          id: list.id!,
          title: l10n.locationNotificationTitle(place),
          body: list.items.isEmpty
              ? l10n.locationNotificationBodyEmpty(list.name)
              : l10n.locationNotificationBody(list.items.length, list.name),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannelId,
              l10n.locationNotificationChannel,
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: '${entry.key}:${list.id}',
        );
        lastNotified['${list.id}'] = now.millisecondsSinceEpoch;
      }
    }
    await prefs.write(key: _prefLastNotified, value: jsonEncode(lastNotified));
    if (online) ApiService.getInstance().dispose();
  }

  static AppLocalizations _lookupLocalizations() {
    try {
      return lookupAppLocalizations(PlatformDispatcher.instance.locale);
    } catch (_) {
      try {
        return lookupAppLocalizations(
          Locale(PlatformDispatcher.instance.locale.languageCode),
        );
      } catch (_) {
        return lookupAppLocalizations(const Locale('en'));
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> shoppingListGeofenceTriggered(
  ng.GeofenceCallbackParams params,
) async {
  try {
    await LocationService.handleGeofenceEvent(params);
  } catch (e) {
    debugPrint('Geofence callback failed: $e');
  }
}
