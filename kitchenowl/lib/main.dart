import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl_standalone.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/background_task.dart';
import 'app.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (!kIsWeb) await findSystemLocale(); //BUG in package for web?
  runApp(App());

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    debugPrint("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  debugPrint('[BackgroundFetch] Headless event received.');

  // setup
  final AuthCubit authCubit = AuthCubit(reloadTokenBeforeRequest: true);

  // fetch
  await BackgroundTask.run(authCubit);

  // teardown
  ApiService.getInstance().dispose();
  await authCubit.close();

  BackgroundFetch.finish(taskId);
}
