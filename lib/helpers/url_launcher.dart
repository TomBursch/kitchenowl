import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

Future<void> openUrl(BuildContext context, String url) async {
  await launch(
    url,
    customTabsOption: CustomTabsOption(
      toolbarColor: Theme.of(context).primaryColor,
      enableDefaultShare: true,
    ),
  );
}

Future<bool> isValidUrl(String url) async {
  try {
    var uri = Uri.parse(url);

    return uri.scheme == "http" || uri.scheme == "https";
  } catch (e) {
    return false;
  }
}
