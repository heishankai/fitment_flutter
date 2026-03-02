import 'package:flutter/material.dart';

/// Tab 页面切回时刷新数据的 Mixin
/// 在 TabNavigator 切换 Tab 时会调用 [onTabSelected]
mixin TabPageRefreshMixin<T extends StatefulWidget> on State<T> {
  /// 切换到此 Tab 时调用，子类实现以刷新接口数据
  void onTabSelected();
}
