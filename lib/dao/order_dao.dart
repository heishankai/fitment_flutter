import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';  

/// 订单 DAO
class OrderDao {
  /// 获取工匠订单列表
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getCraftsmanOrders() async {
    var uri = ApiConfig.createUri('/order/craftsman/list');
    print('📡 请求订单列表 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 订单列表响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取订单列表失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取订单列表失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 接单
  /// [orderId] 订单ID
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    var uri = ApiConfig.createUri('/order/accept');
    print('📡 接单 URI: $uri');
    print('📡 订单ID: $orderId');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({'orderId': orderId}),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 接单响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '接单失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 接单失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取订单详情
  /// [orderId] 订单ID
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    var uri = ApiConfig.createUri('/order/$orderId');
    print('📡 获取订单详情 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 订单详情响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取订单详情失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取订单详情失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 逆地理编码 - 根据经纬度获取地址信息
  /// [latitude] 纬度
  /// [longitude] 经度
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getReverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    var uri = ApiConfig.createUri('/geolocation/reverse-geocode');
    print('📡 逆地理编码 URI: $uri');
    print('📡 经纬度: $latitude, $longitude');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 逆地理编码响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取地址信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 逆地理编码失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }
}
