import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_ui/unifiedpush_ui.dart';

class NotificationService extends UnifiedPushFunctions {
  static const String instanceName = "org.tombursch.kitchenowl";

  static NotificationService? _instance;

  String? endpoint;

  NotificationService.internal();

  static NotificationService getInstance() {
    _instance ??= NotificationService.internal();

    return _instance!;
  }

  Future<void> initialize() async {
    debugPrint("Initializing UnifiedPush");
    UnifiedPush.initialize(
      onNewEndpoint: onNewEndpoint,
      onRegistrationFailed: onRegistrationFailed,
      onUnregistered: onUnregistered,
      onMessage: onNotification,
      linuxDBusName: instanceName,
    ).then((registered) {
      if (registered) {
        UnifiedPush.register(
          instance: instanceName,
        );
      }
    });

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            NotificationService.getInstance()
                .flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        androidImplementation?.requestNotificationsPermission();
      }
    } on Exception catch (_) {
      debugPrint("Exception while granting permissions");
    }
    UnifiedPush.tryUseCurrentOrDefaultDistributor().then((success) {
      if (success) {
        UnifiedPush.register(
          instance: instanceName,
        );
      }
    });
  }

  Future<void> unregister() => UnifiedPush.unregister(instanceName);

  @override
  Future<String?> getDistributor() => UnifiedPush.getDistributor();

  @override
  Future<List<String>> getDistributors() => UnifiedPush.getDistributors();

  @override
  Future<void> registerApp(String instance) =>
      UnifiedPush.registerApp(instance);

  @override
  Future<void> saveDistributor(String distributor) =>
      UnifiedPush.saveDistributor(distributor);

  void onNewEndpoint(PushEndpoint endpoint, String instance) {
    this.endpoint = endpoint.url;
    debugPrint(
        "New endpoint: https://unifiedpush.org/test_wp.html#endpoint=${endpoint.url}&p256dh=${endpoint.pubKeySet?.pubKey}&auth=${endpoint.pubKeySet?.auth}");
  }

  void onRegistrationFailed(FailedReason reason, String instance) {
    onUnregistered(instance);
  }

  void onUnregistered(String instance) {
    endpoint = null;
    debugPrint("unregistered ${instance}");
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _notificationInitialized = false;

  Map<String, String> decodeMessageContentsUri(String message) {
    List<String> uri = Uri.decodeComponent(message).split("&");
    Map<String, String> decoded = {};
    for (var i in uri) {
      try {
        decoded[i.split("=")[0]] = i.split("=")[1];
      } on Exception {
        debugPrint("Couldn't decode $i");
      }
    }
    return decoded;
  }

  Future<bool> onNotification(
    PushMessage message,
    String instance,
  ) async {
    debugPrint("instance $instance");
    debugPrint("onNotification");
    var payload = utf8.decode(message.content);

    String title = 'KitchenOwl'; // Default title
    String body = 'Could not get the content'; // Default body

    try {
      // Try to decode title and message (JSON)
      Map<String, String> decodedMessage = decodeMessageContentsUri(payload);
      title = decodedMessage['title'] ?? title;
      body = decodedMessage['message'] ?? body;
    } catch (e) {
      // If decoding fails, use plain payload as body
      body = payload.isNotEmpty ? payload : 'Empty message';
    }

    debugPrint(title);
    if (!_notificationInitialized) _initNotifications();

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'KitchenOwl',
      'KitchenOwl',
      playSound: false,
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecondsSinceEpoch % 100000000,
      title,
      body,
      platformChannelSpecifics,
    );
    return true;
  }

  void _initNotifications() async {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'open');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
    );
    _notificationInitialized = await flutterLocalNotificationsPlugin
            .initialize(initializationSettings) ??
        false;
  }
}
