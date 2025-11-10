import 'package:flutter/material.dart';
import 'package:fitment_flutter/pages/login_page/index.dart';
import 'package:fitment_flutter/navigator/tab_navigator.dart';

class NavigatorUtil {
  // 当前上下文 , 用于在获取不到上下文的时候使用，比如在静态方法中
  static BuildContext? _context;

  static updateContext(BuildContext context) {
    NavigatorUtil._context = context;
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
    Navigator.pushReplacement(
        _context!, MaterialPageRoute(builder: (context) => const LoginPage()));
  }
}
