import 'package:flutter/foundation.dart';

/// API 配置类
class ApiConfig {
  // 开发环境 API 地址
  static const String _devBaseUrl = 'localhost:3000';

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
      // 开发环境：http://localhost:3000/admin/login
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
