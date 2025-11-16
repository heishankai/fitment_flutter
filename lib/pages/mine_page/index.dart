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
      url: 'http://localhost:5173/fitment-h5/mine',
      statusBarColor: '00cec9',
      hideAppBar: true,
    ));
  }
}
