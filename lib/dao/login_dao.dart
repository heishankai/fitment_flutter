import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

/// 登录 DAO
class LoginDao {
  static const token = 'token';

  static Login({required String phone, required String verifyCode}) async {
    var uri = Uri.http('localhost:3000', '/admin/login');

    final response = await http.post(
      uri,
      headers: getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'verifyCode': verifyCode,
      }),
    );

    Utf8Decoder utf8Decoder = const Utf8Decoder();
    String responseBody = utf8Decoder.convert(response.bodyBytes);
    var result = json.decode(responseBody);

    // 成功时保存 token
    if (result['success'] == true || result['code'] == 200) {
      _saveToken(result);
    }

    return result;
  }

  // 保存 token
  static void _saveToken(result) {
    var tokenValue = result['data'];

    print('tokenValue==============>: $tokenValue');

    if (tokenValue != null && tokenValue is String) {
      HiCache.getInstance().setString(token, tokenValue);
    }
  }

  // 获取 token
  static String? getToken() {
    return HiCache.getInstance().get(token);
  }

  // 退出登录
  static void logout() {
    HiCache.getInstance().remove(token);
  }
}
