import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

/// 登录 DAO
class LoginDao {
  static const token = 'token';

  /// 获取短信验证码
  /// [phone] 手机号码
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getSmsCode({
    required String phone,
  }) async {
    var uri = ApiConfig.createUri('/sms/send-code');
    print('📡 请求验证码 URI: $uri');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({
          'phone': phone,
        }),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 验证码响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取验证码失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取验证码失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  static Login({required String phone, required String verifyCode}) async {
    // 根据环境动态选择 API 地址
    var uri = ApiConfig.createUri('/admin/login');
    print('📡 请求 URI: $uri');

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
