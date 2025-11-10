import 'package:flutter/material.dart';

/// 扩展int类型
extension IntFix on int {
  /// 获取对应大小
  /// @return 对应大小
  /// 例：10.px => 10 * ratio
  double get px => ScreenHelper.getPx(toDouble());
}

/// 扩展double类型
extension DoubleFix on double {
  /// 获取对应大小
  /// @return 对应大小
  /// 例：10.0.px => 10.0 * ratio
  double get px => ScreenHelper.getPx(this);
}

/// 屏幕适配工具类
class ScreenHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double ratio;

  /// 初始化屏幕适配
  /// @param context 上下文
  /// @param designWidth 设计稿宽度
  static void init(BuildContext context, {double? designWidth = 375}) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width; // 屏幕宽度
    screenHeight = _mediaQueryData.size.height; // 屏幕高度
    ratio = screenWidth / designWidth!; // 屏幕宽度 / 设计稿宽度
  }

  /// 获取设计稿对应大小
  /// @param size 设计稿大小
  /// @return 对应大小
  static double getPx(double size) {
    return ScreenHelper.ratio * size;
  }
}
