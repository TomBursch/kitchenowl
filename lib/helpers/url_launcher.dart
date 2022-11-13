import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

Future<void> openUrl(BuildContext context, String url) async {
  return (Platform.isAndroid || Platform.isIOS)
      ? await launch(
          url,
          customTabsOption: CustomTabsOption(
            toolbarColor: Theme.of(context).primaryColor,
            enableDefaultShare: true,
          ),
        )
      : await ul.launchUrl(Uri.parse(url));
}

Future<bool> isValidUrl(String url) async {
  try {
    var uri = Uri.parse(url);

    return uri.scheme == "http" || uri.scheme == "https";
  } catch (e) {
    return false;
  }
}
