// Flutter 核心组件库
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/pages/login/index.dart';
import 'package:fitment_flutter/components/tab_navigator.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/utils/app_error_handling.dart';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandling.install();
  // 解决安卓真机顶部状态栏灰色问题：设置状态栏颜色与主色一致
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: AppErrorHandling.scaffoldMessengerKey,
      title: '智惠装工匠',
      debugShowCheckedModeBanner: false, // 移除调试标签
      // 配置应用主题，参考 fitment-mini-program uni.scss
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textInverse,
          secondary: AppColors.primary,
          onSecondary: AppColors.textInverse,
          error: AppColors.error,
          surface: AppColors.bg,
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
