import 'dart:io';
import 'package:flutter/foundation.dart';

/// H5 页面配置类
class H5Config {
  // 开发环境 H5 地址
  static String get _devBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5173'; // Android 模拟器访问宿主机的特殊 IP
    }
    return 'http://127.0.0.1:5173'; // iOS 模拟器需要使用 127.0.0.1
  }

  // 生产环境 H5 地址
  static const String _prodBaseUrl = 'https://zjiangyun.cn';

  /// 获取 H5 页面的完整 URL
  /// [path] H5 页面路径，如 '/fitment-h5/home'
  static String getH5Url(String path) {
    String url;
    if (kDebugMode) {
      // 开发环境：http://127.0.0.1:5173/fitment-h5/home (iOS) 或 http://10.0.2.2:5173/fitment-h5/home (Android)
      url = '$_devBaseUrl$path';
      debugPrint('🔧 [开发环境] H5 地址: $url');
    } else {
      // 生产环境：https://zjiangyun.cn/fitment-h5/home
      url = '$_prodBaseUrl$path';
      debugPrint('🚀 [生产环境] H5 地址: $url');
    }
    return url;
  }
}
