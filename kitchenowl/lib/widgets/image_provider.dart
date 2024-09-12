import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:kitchenowl/services/api/api_service.dart';

String buildUrl(String url) {
  if (_urlIsLocal(url)) {
    return '${ApiService.getInstance().baseUrl}/upload/$url';
  }

  return url;
}

bool _urlIsLocal(String url) => !url.contains('/');

ImageProvider<Object> getImageProvider(
  BuildContext context,
  String image, {
  int? maxWidth,
  int? maxHeight,
}) {
  return CachedNetworkImageProvider(
    buildUrl(image),
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    headers: _urlIsLocal(image) ? ApiService.getInstance().headers : null,
    imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
  );
}
