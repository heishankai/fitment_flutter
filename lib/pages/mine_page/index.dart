import 'package:flutter/material.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/pages/screen_page.dart';

/// 我的页面
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            NavigatorUtil.push(context, const ScreenPage());
          },
          child: const Text('跳转到屏幕适配测试'),
        ),
      ),
    );
  }
}
