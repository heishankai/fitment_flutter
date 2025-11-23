import 'package:flutter/material.dart';
import 'package:fitment_flutter/pages/home_page/index.dart';
import 'package:fitment_flutter/pages/mine_page/index.dart';
import 'package:fitment_flutter/pages/message_page/index.dart';
import 'package:fitment_flutter/pages/income_page/index.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';

/// 首页底部导航器
class TabNavigator extends StatefulWidget {
  const TabNavigator({super.key});

  @override
  State<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  final PageController _controller = PageController(
    initialPage: 0, // 初始页
    // keepPage: true, // 是否保持页面状态
  );

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 统一初始化屏幕适配
    ScreenHelper.init(context);

    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(), // 禁止左右滑动切换页面
        children: const [
          HomePage(),
          IncomePage(),
          MessagePage(),
          MinePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _controller.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed, // 固定类型，避免超过4个item时的问题
        selectedItemColor: Theme.of(context).colorScheme.primary, // 选中时使用主题色
        unselectedItemColor: Colors.grey, // 未选中时使用灰色
        items: [
          _bottomItem(Icons.home, '首页'),
          _bottomItem(Icons.account_balance_wallet, '收入'),
          _bottomItem(Icons.chat_bubble, '消息'),
          _bottomItem(Icons.person, '我的'),
        ],
      ),
    );
  }

  // 创建底部导航栏 item
  BottomNavigationBarItem _bottomItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}
