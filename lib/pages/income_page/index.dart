import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:flutter/material.dart';

/// 收入页面
class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          child: const Text('收入'),
          onTap: () {
            NavigatorUtil.jumpH5(
                context: context,
                url: 'http://localhost:5173/fitment-h5/',
                title: '聊天',
                statusBarColor: '00cec9');
          },
        ),
      ),
    );
  }
}
