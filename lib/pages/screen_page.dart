import 'package:fitment_flutter/utils/view_util.dart';
import 'package:flutter/material.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';

class ScreenPage extends StatefulWidget {
  const ScreenPage({super.key});

  @override
  State<ScreenPage> createState() => _ScreenPageState();
}

class _ScreenPageState extends State<ScreenPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('屏幕适配测试'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: const Text('默认大小'),
            ),
            hiSpace(height: 40.px),
            Container(
              width: 200.px,
              height: 200.px,
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: const Text('适配大小'),
            ),
          ],
        ),
      ),
    );
  }
}
