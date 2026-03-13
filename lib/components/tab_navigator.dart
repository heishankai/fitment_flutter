import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/pages/home/h5_home.dart';
import 'package:fitment_flutter/pages/message/index.dart';
import 'package:fitment_flutter/pages/mine/index.dart';
import 'package:fitment_flutter/pages/income/index.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';

class TabNavigator extends StatefulWidget {
  const TabNavigator({super.key});

  @override
  State<TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<TabNavigator> {
  // 当前选中的底部导航栏索引
  int _currentIndex = 0;

  // 用于获取各 Tab 页 State，以便切换时调用刷新
  final List<GlobalKey<State>> _pageKeys = [
    GlobalKey<State>(),
    GlobalKey<State>(),
    GlobalKey<State>(),
    GlobalKey<State>(),
  ];

  // 保存所有页面实例，实现页面缓存
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeH5Page(key: _pageKeys[0]),
      IncomePage(key: _pageKeys[1]),
      MessagePage(key: _pageKeys[2]),
      MinePage(key: _pageKeys[3]),
    ];
  }

  // 底部导航栏配置
  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined),
      activeIcon: Icon(Icons.account_balance_wallet),
      label: '收入',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      activeIcon: Icon(Icons.chat_bubble),
      label: '消息',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  /// 处理底部导航栏点击事件
  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      // 切换到此 Tab 时调用该页面的刷新接口
      final state = _pageKeys[index].currentState;
      if (state is TabPageRefreshMixin) {
        state.onTabSelected();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 更新 NavigatorUtil 的 context，以便在 dao 中使用
    NavigatorUtil.updateContext(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // 禁用点击波纹效果
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed, // 固定类型，避免图标和文字重叠
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          // 添加背景色，提升视觉效果
          backgroundColor: AppColors.bg,
          elevation: 8,
          items: _bottomNavItems,
        ),
      ),
    );
  }
}
