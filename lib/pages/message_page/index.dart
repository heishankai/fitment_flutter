import 'package:fitment_flutter/pages/hi_webview.dart';
import 'package:flutter/material.dart';

/// 消息页面
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: HiWebView(
      url: 'http://localhost:5173/fitment-h5/wechat-msg',
      statusBarColor: '00cec9',
      title: '我的',
      hideAppBar: true,
    ));
  }
}
