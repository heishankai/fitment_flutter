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
  bool _showBottomNav = true; // 是否显示底部导航栏

  /// 检查 URL 是否是主页面路由（mine 或 message）
  /// 只允许主页面本身，不包括子路径
  bool _isMainPage(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      // 检查是否是 mine 主页面
      bool isMineMain = path == '/fitment-h5/mine' || path == '/mine';
      // 检查是否是 message 主页面
      bool isMessageMain = path == '/fitment-h5/chat/craftsman' || 
                          path == '/chat/craftsman';
      return isMineMain || isMessageMain;
    } catch (e) {
      return false;
    }
  }

  /// 监听 MinePage 的路由变化
  void _onMinePageUrlChanged(String newUrl) {
    // 如果是主页面，显示底部导航栏；否则隐藏
    bool shouldShow = _isMainPage(newUrl);
    
    // 立即更新状态，不使用延迟
    if (_showBottomNav != shouldShow && mounted) {
      setState(() {
        _showBottomNav = shouldShow;
      });
    }
  }

  /// 监听 MessagePage 的路由变化
  void _onMessagePageUrlChanged(String newUrl) {
    // 如果是主页面，显示底部导航栏；否则隐藏
    bool shouldShow = _isMainPage(newUrl);
    
    // 立即更新状态，不使用延迟
    if (_showBottomNav != shouldShow && mounted) {
      setState(() {
        _showBottomNav = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 统一初始化屏幕适配
    ScreenHelper.init(context);

    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(), // 禁止左右滑动切换页面
        children: [
          const HomePage(),
          const IncomePage(),
          MessagePage(
            onUrlChanged: _onMessagePageUrlChanged, // 监听路由变化
          ),
          MinePage(
            onUrlChanged: _onMinePageUrlChanged, // 监听路由变化
          ),
        ],
      ),
      bottomNavigationBar: _showBottomNav
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _controller.jumpToPage(index);
                  
                  // 如果切换到"消息"或"我的"标签，根据当前 URL 决定是否显示底部导航栏
                  if (index == 2 || index == 3) {
                    // 切换到"消息"或"我的"页面时，默认显示底部导航栏
                    // 路由变化会通过回调更新状态
                    _showBottomNav = true;
                  } else {
                    // 切换到其他页面时，始终显示底部导航栏
                    _showBottomNav = true;
                  }
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
            )
          : null, // 直接隐藏，无动画
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
