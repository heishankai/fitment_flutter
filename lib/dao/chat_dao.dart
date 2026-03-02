import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';

/// 聊天 DAO
class ChatDao {
  /// 获取工匠用户的所有聊天房间列表
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getCraftsmanRooms() async {
    var uri = ApiConfig.createUri('/craftsman-wechat-chat/rooms/craftsman');
    print('📡 请求聊天房间列表 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 聊天房间列表响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取聊天列表失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取聊天房间列表失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取用户未读通知数量
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    var uri = ApiConfig.createUri('/system-notification/unread-count');
    print('📡 请求未读通知数量 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 未读通知数量响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取未读通知数量失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取未读通知数量失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }
}
