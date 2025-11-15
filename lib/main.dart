// Flutter 核心组件库
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/pages/login_page/index.dart';
import 'package:fitment_flutter/navigator/tab_navigator.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // 配置应用主题，使用 #00cec9 作为主色调，启用 Material 3 设计
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00CEC9), // #00cec9
          onPrimary: Colors.white,
          secondary: Color(0xFF00CEC9),
          onSecondary: Colors.white,
        ),
        useMaterial3: true,
      ),
      // 设置应用的首页
      home: FutureBuilder<dynamic>(
        future: HiCache.preInit(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          // 初始化屏幕适配工具
          ScreenHelper.init(context);

          if (snapshot.connectionState == ConnectionState.done) {
            if (LoginDao.getToken() == null) {
              return const LoginPage();
            }
            return const TabNavigator();
          }
          // 进度条
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
