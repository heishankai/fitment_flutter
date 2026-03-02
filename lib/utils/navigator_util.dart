import 'package:fitment_flutter/pages/webview.dart';
import 'package:flutter/material.dart';
import 'package:fitment_flutter/pages/login/index.dart';
import 'package:fitment_flutter/components/tab_navigator.dart';
import 'package:flutter/services.dart';

class NavigatorUtil {
  /// 用于在获取不到 context 的时候使用，如在dao中页面跳转使用，需要在 TabNavigator 中赋值
  /// 如果 TabNavigator 被销毁，_context 将无法使用
  static BuildContext? _context;

  // static BuildContext? _context;

  static updateContext(BuildContext context) {
    NavigatorUtil._context = context;
  }

  /// 返回上一页
  static pop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      /// 退出app
      SystemNavigator.pop();
    }
  }

  /// 跳转H5页面，返回 Future 便于在页面返回后执行回调
  static Future<T?> jumpH5<T>({
    BuildContext? context,
    required String url,
    String? title,
    bool? hideAppBar,
    String? statusBarColor,
  }) async {
    BuildContext? safeContext;

    if (url.isEmpty) {
      return null as T?;
    }

    if (context != null) {
      safeContext = context;
    } else if (_context?.mounted ?? false) {
      safeContext = _context;
    } else {
      debugPrint('🚫 跳转H5页面失败，context 为空');
      return null as T?;
    }

    return Navigator.push<T>(
      safeContext!,
      MaterialPageRoute(
        builder: (context) => HiWebView(
          url: url,
          title: title,
          hideAppBar: hideAppBar ?? false,
          statusBarColor: statusBarColor,
        ),
      ),
    );
  }

  /// 跳转到指定页面
  static push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// 跳转到首页
  static goToHome(BuildContext context) {
    /// 跳转到主页并不让返回
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const TabNavigator()));
  }

  /// 跳转到登录页
  static goToLogin() {
    /// 跳转到登录页并不让返回
    if (_context == null || !_context!.mounted) {
      debugPrint('🚫 跳转到登录页失败，context 为空或已销毁');
      return;
    }
    Navigator.pushReplacement(
        _context!, MaterialPageRoute(builder: (context) => const LoginPage()));
  }
}
