import 'package:flutter/material.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于 AutomaticKeepAliveClientMixin
    NavigatorUtil.updateContext(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          _loginOutButton(),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '登录成功！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginOutButton() {
    return ElevatedButton(
      onPressed: () {
        LoginDao.logout();
        NavigatorUtil.goToLogin();
      },
      child: const Text('退出登录'),
    );
  }

  /// 保持页面不卸载，不会重新加载数据
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    // 必须调用 super.dispose() 来释放 mixin 中的资源
    super.dispose();
  }
}
