import 'package:fitment_flutter/pages/hi_webview.dart';
import 'package:flutter/material.dart';

/// 消息页面
class MessagePage extends StatefulWidget {
  /// 路由变化回调函数
  /// 当 WebView 的 URL 发生变化时会被调用
  /// 参数：newUrl - 新的 URL 地址
  final void Function(String newUrl)? onUrlChanged;

  const MessagePage({super.key, this.onUrlChanged});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
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
    super.build(context);
    return Scaffold(
        body: HiWebView(
      url: 'http://localhost:5173/fitment-h5/chat/craftsman',
      statusBarColor: '00cec9',
      hideAppBar: true,
      onUrlChanged: _onUrlChanged, // 添加路由变化监听
    ));
  }
}
