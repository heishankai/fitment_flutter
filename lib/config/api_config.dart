import 'dart:io';
import 'package:flutter/foundation.dart';

/// API 配置类
class ApiConfig {
  // 开发环境 API 地址
  // Android 模拟器需要使用 10.0.2.2 访问宿主机
  static String get _devBaseUrl {
    if (Platform.isAndroid) {
      return '10.0.2.2:3000';  // Android 模拟器访问宿主机的特殊 IP
    }
    return 'localhost:3000';  // iOS 模拟器或真机可以使用 localhost
  }

  // 生产环境 API 地址
  static const String _prodBaseUrl = 'zjiangyun.cn';

  // 生产环境 API 路径前缀
  static const String _prodApiPrefix = '/api';

  /// 创建 URI（自动根据环境选择 HTTP 或 HTTPS）
  /// [path] 接口路径，如 '/admin/login'
  /// [queryParameters] 查询参数（可选）
  static Uri createUri(String path, [Map<String, String>? queryParameters]) {
    Uri uri;
    if (kDebugMode) {
      // 开发环境：http://10.0.2.2:3000/admin/login (Android) 或 http://localhost:3000/admin/login (iOS)
      uri = Uri.http(_devBaseUrl, path, queryParameters);
      print('🔧 [开发环境] API 地址: ${uri.toString()}');
    } else {
      // 生产环境：https://zjiangyun.cn/api/admin/login
      uri = Uri.https(_prodBaseUrl, '$_prodApiPrefix$path', queryParameters);
      print('🚀 [生产环境] API 地址: ${uri.toString()}');
    }
    return uri;
  }
}
