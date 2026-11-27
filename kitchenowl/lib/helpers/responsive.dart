import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum DeviceScreenType { mobile, tablet, desktop, watch }

DeviceScreenType getDeviceType(Size size) {
  final isWebOrDesktop = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  final deviceWidth = isWebOrDesktop ? size.width : size.shortestSide;

  if (deviceWidth >= 950) {
    return DeviceScreenType.desktop;
  }
  if (deviceWidth >= 600) {
    return DeviceScreenType.tablet;
  }
  if (deviceWidth < 300) {
    return DeviceScreenType.watch;
  }
  return DeviceScreenType.mobile;
}

T getValueForScreenType<T>({
  required BuildContext context,
  required T mobile,
  T? tablet,
  T? desktop,
  T? watch,
}) {
  final deviceScreenType = getDeviceType(MediaQuery.sizeOf(context));

  if (deviceScreenType == DeviceScreenType.desktop) {
    if (desktop != null) return desktop;
    if (tablet != null) return tablet;
  }

  if (deviceScreenType == DeviceScreenType.tablet) {
    if (tablet != null) return tablet;
  }

  if (deviceScreenType == DeviceScreenType.watch && watch != null) {
    return watch;
  }

  return mobile;
}
