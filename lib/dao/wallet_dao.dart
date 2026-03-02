import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';

/// 钱包 DAO
class WalletDao {
  /// 获取钱包信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getWalletInfo() async {
    var uri = ApiConfig.createUri('/wallet');
    print('📡 请求钱包信息 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 钱包信息响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取钱包信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取钱包信息失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取用户的银行卡信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getBankCard() async {
    var uri = ApiConfig.createUri('/craftsman-bank-card');
    print('📡 请求银行卡信息 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 银行卡信息响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取银行卡信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取银行卡信息失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取账户明细（钱包交易记录）
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getWalletTransaction() async {
    var uri = ApiConfig.createUri('/wallet-transaction/my');
    print('📡 请求账户明细 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 账户明细响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取账户明细失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取账户明细失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 申请提现
  /// [amount] 提现金额
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> applyWithdraw({
    required double amount,
  }) async {
    var uri = ApiConfig.createUri('/withdraw/create');
    print('📡 申请提现 URI: $uri');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode({
          'amount': amount,
        }),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 申请提现响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '申请提现失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 申请提现失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取提现记录
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getWithdrawRecord() async {
    var uri = ApiConfig.createUri('/withdraw/my');
    print('📡 请求提现记录 URI: $uri');

    try {
      final response = await http.get(
        uri,
        headers: getHeaders(),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 提现记录响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '获取提现记录失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 获取提现记录失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 绑定银行卡
  /// [data] 银行卡信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> bindBankCard({
    required Map<String, dynamic> data,
  }) async {
    var uri = ApiConfig.createUri('/craftsman-bank-card');
    print('📡 绑定银行卡 URI: $uri');

    try {
      final response = await http.post(
        uri,
        headers: getHeaders(),
        body: jsonEncode(data),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 绑定银行卡响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '绑定银行卡失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 绑定银行卡失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 更新银行卡
  /// [data] 银行卡信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> updateBankCard({
    required Map<String, dynamic> data,
  }) async {
    var uri = ApiConfig.createUri('/craftsman-bank-card');
    print('📡 更新银行卡 URI: $uri');

    try {
      final response = await http.put(
        uri,
        headers: getHeaders(),
        body: jsonEncode(data),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 更新银行卡响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '更新银行卡失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 更新银行卡失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }
}
