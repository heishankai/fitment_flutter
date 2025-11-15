import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

/// 登录 DAO
class LoginDao {
  static const token = 'token';
  static const userInfo = 'userInfo';

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

  /// 工匠用户登录/注册
  /// [phone] 手机号码
  /// [verifyCode] 验证码
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> Login({
    required String phone,
    required String verifyCode,
  }) async {
    var uri = ApiConfig.createUri('/craftsman-user/login');
    print('📡 请求登录 URI: $uri');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({
          'phone': phone,
          'code': verifyCode,
        }),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 登录响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 成功时保存 token 和用户信息
        if (result['success'] == true || result['code'] == 200) {
          _saveToken(result);
          _saveUserInfo(result);
        }
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '登录失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 登录失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取用户信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getUserInfo() async {
    var uri = ApiConfig.createUri('/craftsman-user/info');
    print('📡 请求用户信息 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 用户信息响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取用户信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取用户信息失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  // 保存 token
  static void _saveToken(result) {
    // 新的接口返回格式: { success: true, data: { phone, nickname, avatar, token } }
    var data = result['data'];

    print('保存 token，data: $data');

    if (data != null && data is Map) {
      var tokenValue = data['token'];

      if (tokenValue != null && tokenValue is String) {
        HiCache.getInstance().setString(token, tokenValue);
        print('✅ Token 保存成功');
      }
    }
  }

  // 获取 token
  static String? getToken() {
    return HiCache.getInstance().get(token);
  }

  // 保存用户信息到本地缓存
  static void _saveUserInfo(result) {
    if (result['data'] != null && result['data'] is Map) {
      var data = result['data'] as Map<String, dynamic>;
      // 将用户信息保存为 JSON 字符串
      var userInfoJson = jsonEncode(data);
      HiCache.getInstance().setString(userInfo, userInfoJson);
      print('✅ 用户信息保存成功');
    }
  }

  // 从本地缓存获取用户信息
  static Map<String, dynamic>? getLocalUserInfo() {
    var userInfoJson = HiCache.getInstance().get(userInfo);
    if (userInfoJson != null && userInfoJson is String) {
      try {
        return jsonDecode(userInfoJson) as Map<String, dynamic>;
      } catch (e) {
        print('❌ 解析用户信息失败: $e');
        return null;
      }
    }
    return null;
  }

  // 退出登录
  static void logout() {
    HiCache.getInstance().remove(token);
    HiCache.getInstance().remove(userInfo);
  }
}
