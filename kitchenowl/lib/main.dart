import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl_standalone.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/background_task.dart';
import 'app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (!kIsWeb) await findSystemLocale(); //BUG in package for web?
  runApp(App());

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  await handleBackgroundFetchHeadlessTask(
    task.taskId,
    isTimeout: task.timeout,
  );
}

@visibleForTesting
Future<void> handleBackgroundFetchHeadlessTask(
  String taskId, {
  required bool isTimeout,
  Future<void> Function()? runTask,
  void Function()? dispose,
  void Function(String)? finish,
}) async {
  final execute = runTask ?? BackgroundTask.runHeadless;
  final cleanUp = dispose ?? () => ApiService.getInstance().dispose();
  final complete = finish ??
      (String completedTaskId) {
        BackgroundFetch.finish(completedTaskId);
      };

  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    debugPrint("[BackgroundFetch] Headless task timed-out: $taskId");
    complete(taskId);
    return;
  }
  debugPrint('[BackgroundFetch] Headless event received.');

  try {
    await execute();
  } finally {
    cleanUp();
    complete(taskId);
  }
}
