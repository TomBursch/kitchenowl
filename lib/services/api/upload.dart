import 'dart:convert';
import 'package:kitchenowl/helpers/named_bytearray.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension UploadApi on ApiService {
  static const baseRoute = '/upload';

  Future<String?> uploadBytes(NamedByteArray file) async {
    final res = await postBytes(baseRoute, file);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);

    return body['filename'];
  }
}
