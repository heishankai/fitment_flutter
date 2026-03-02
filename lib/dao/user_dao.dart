import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:fitment_flutter/dao/header_util.dart';
import 'package:fitment_flutter/config/api_config.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

/// 用户信息 DAO
class UserDao {
  /// 获取用户信息
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> getUserInfo() async {
    var uri = ApiConfig.createUri('/craftsman-user');
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

  /// 更新用户信息
  /// [params] 用户信息参数，如 { nickname, avatar }
  /// 返回 API 响应结果
  static Future<Map<String, dynamic>> updateUserInfo(
      Map<String, dynamic> params) async {
    var uri = ApiConfig.createUri('/craftsman-user');
    print('📡 更新用户信息 URI: $uri');
    print('📡 更新参数: $params');

    try {
      final response = await http.put(
        uri,
        headers: getHeaders(),
        body: jsonEncode(params),
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 更新用户信息响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 更新成功后，更新本地缓存的用户信息
        if (result['success'] == true && result['data'] != null) {
          // 保存用户信息到本地缓存
          final data = result['data'] as Map<String, dynamic>;
          final userInfoJson = jsonEncode(data);
          HiCache.getInstance().setString(LoginDao.userInfo, userInfoJson);
          print('✅ 用户信息更新成功');
        }
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '更新用户信息失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 更新用户信息失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }

  /// 获取文件的 MIME 类型
  static MediaType _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'svg':
        return MediaType('image', 'svg+xml');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'avi':
        return MediaType('video', 'x-msvideo');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        // 默认使用 jpeg
        return MediaType('image', 'jpeg');
    }
  }

  /// 上传图片
  /// [imageFile] 图片文件
  /// 返回 API 响应结果，包含图片 URL
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    var uri = ApiConfig.createUri('/upload');
    print('📡 上传图片 URI: $uri');
    print('📡 上传文件路径: ${imageFile.path}');

    try {
      // 创建 multipart request
      var request = http.MultipartRequest('POST', uri);

      // 添加 token 到 headers
      final token = LoginDao.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // 获取文件的 MIME 类型
      final mediaType = _getMediaType(imageFile.path);
      print('📡 文件 MIME 类型: ${mediaType.mimeType}');

      // 添加文件，字段名必须是 'file'，并指定正确的 content-type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: mediaType,
        ),
      );

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      print('📨 上传图片响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return result;
      } else {
        // HTTP 状态码错误
        return {
          'success': false,
          'message': result['message'] ?? '上传图片失败',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ 上传图片失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接',
        'code': 500,
      };
    }
  }
}
