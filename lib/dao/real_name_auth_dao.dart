import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';

/// 实名认证 DAO
class RealNameAuthDao {
  /// 提交实名认证
  /// [params] 认证信息参数，包含：
  ///   - card_name: 证件名称
  ///   - card_number: 证件号码
  ///   - card_address: 证件住址
  ///   - card_start_date: 证件有效期开始日期
  ///   - card_end_date: 证件有效期结束日期
  ///   - card_front_image: 身份证正面图片URL数组
  ///   - card_reverse_image: 身份证反面图片URL数组
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> submitAuth(
      Map<String, dynamic> params) async {
    var uri = ApiConfig.createUri('/is-verified');
    print('📡 提交实名认证 URI: $uri');
    print('📡 提交参数: $params');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode(params),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 提交实名认证响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '提交实名认证失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 提交实名认证失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取用户实名认证信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getAuthInfo() async {
    var uri = ApiConfig.createUri('/is-verified/my');
    print('📡 获取实名认证信息 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 获取实名认证信息响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取实名认证信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取实名认证信息失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }
}
