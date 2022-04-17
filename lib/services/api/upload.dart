import 'dart:convert';
import 'dart:io';
import 'package:kitchenowl/services/api/api_service.dart';

extension UploadApi on ApiService {
  static const baseRoute = '/upload';

  Future<String?> uploadFile(File file) async {
    final res = await postFile(baseRoute, file);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);

    return body['name'];
  }
}
