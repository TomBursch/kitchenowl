import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as ul;
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;

Future<void> openUrl(BuildContext context, String url,
    {bool webOpenNewTab = true}) async {
  if (!isValidUrl(url)) return;

  return (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      ? await ct.launchUrl(
          Uri.parse(url),
          customTabsOptions: ct.CustomTabsOptions(
            colorSchemes: ct.CustomTabsColorSchemes.defaults(
              toolbarColor: Theme.of(context).colorScheme.primary,
            ),
            shareState: ct.CustomTabsShareState.on,
            browser: ct.CustomTabsBrowserConfiguration(
              fallbackCustomTabs: const [
                'org.mozilla.firefox',
                'org.mozilla.fenix',
                'com.vivaldi.browser',
                'com.microsoft.emmx',
              ],
            ),
          ),
          safariVCOptions: ct.SafariViewControllerOptions(
            preferredBarTintColor: Theme.of(context).colorScheme.primary,
            preferredControlTintColor: Theme.of(context).colorScheme.onPrimary,
            barCollapsingEnabled: true,
            entersReaderIfAvailable: false,
            dismissButtonStyle: ct.SafariViewControllerDismissButtonStyle.close,
          ),
        )
      : await ul.launchUrl(
          Uri.parse(url),
          webOnlyWindowName: webOpenNewTab ? '_blank' : '_self',
        );
}

bool isValidUrl(String url) {
  try {
    var uri = Uri.parse(url);

    return uri.scheme == "http" || uri.scheme == "https";
  } catch (e) {
    return false;
  }
}
