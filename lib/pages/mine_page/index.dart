import 'package:fitment_flutter/pages/hi_webview.dart';
import 'package:flutter/material.dart';

class MinePage extends StatefulWidget {
  /// 路由变化回调函数
  /// 当 WebView 的 URL 发生变化时会被调用
  /// 参数：newUrl - 新的 URL 地址
  final void Function(String newUrl)? onUrlChanged;

  const MinePage({super.key, this.onUrlChanged});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }

  /// 监听 WebView 路由变化
  void _onUrlChanged(String newUrl) {
    // 立即通知外部路由变化，不使用延迟
    widget.onUrlChanged?.call(newUrl);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于 AutomaticKeepAliveClientMixin
    return Scaffold(
        body: HiWebView(
      url: 'http://localhost:5173/fitment-h5/mine',
      statusBarColor: '00cec9',
      hideAppBar: true,
      onUrlChanged: _onUrlChanged, // 添加路由变化监听
    ));
  }
}
