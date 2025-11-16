import 'package:fitment_flutter/pages/hi_webview.dart';
import 'package:flutter/material.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: HiWebView(
      url: 'http://localhost:5176/fitment-h5/mine?name=张三&age=18',
      statusBarColor: '00cec9',
      title: '我的',
      hideAppBar: true,
    ));
  }
}
