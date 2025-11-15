import 'package:flutter/material.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/pages/screen_page.dart';
import 'package:fitment_flutter/pages/mine_page/components/menu_item.dart';
import 'package:fitment_flutter/pages/mine_page/components/edit_profile_button.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';

/// 我的页面
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final int completedOrders = 156;
  final double rating = 4.9;
  final String nickname = '张三'; // 昵称

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildMenuList(),
        ],
      ),
    );
  }

  /// 构建顶部头部区域
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 渐变背景
              Container(
                height: 200.px,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF00CEC9), Color(0xFF00B4D8)],
                  ),
                ),
              ),
              // 用户信息卡片
              Positioned(
                top: 120.px,
                left: 16.px,
                right: 16.px,
                child: _buildUserCard(),
              ),
            ],
          ),
          // 底部间距，确保卡片不遮挡菜单
          SizedBox(height: 190.px),
        ],
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard() {
    return Container(
      padding: EdgeInsets.all(20.px),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.px,
            offset: Offset(0, 4.px),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileSection(),
          SizedBox(height: 20.px),
          _buildStatsSection(),
          SizedBox(height: 20.px),
          EditProfileButton(
            onTap: () {},
          ),
        ],
      ),
    );
  }

  /// 构建头像和认证标签区域
  Widget _buildProfileSection() {
    return Row(
      children: [
        // 头像
        Stack(
          children: [
            Container(
              width: 80.px,
              height: 80.px,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00CEC9), Color(0xFF00B4D8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00CEC9).withOpacity(0.3),
                    blurRadius: 12.px,
                    offset: Offset(0, 4.px),
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(3.px),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(Icons.person, size: 50.px, color: Colors.grey),
              ),
            ),
          ],
        ),
        SizedBox(width: 16.px),
        // 昵称和认证标签
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 昵称
              Text(
                nickname,
                style: TextStyle(
                  fontSize: 20.px,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.px),
              // 认证标签
              Row(
                children: [
                  _buildBadge('已实名', Colors.blue, Icons.verified),
                  SizedBox(width: 8.px),
                  _buildBadge('技能认证', Colors.orange, Icons.workspace_premium),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建认证标签
  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.px, vertical: 6.px),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.px),
        border: Border.all(color: color.withOpacity(0.3), width: 1.px),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.px, color: color),
          SizedBox(width: 6.px),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.px,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据区域
  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatItem(completedOrders.toString(), '已完成订单')),
        Container(width: 1.px, height: 50.px, color: Colors.grey[200]),
        Expanded(child: _buildStatItem(rating.toString(), '综合评分')),
      ],
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28.px,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6.px),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.px,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建菜单列表
  Widget _buildMenuList() {
    return SliverPadding(
      padding: EdgeInsets.only(top: 12.px, bottom: 20.px),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            MenuItem(
              icon: Icons.verified_user,
              color: Colors.blue,
              title: '实名认证',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.description,
              color: Colors.purple,
              title: '我的订单',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.workspace_premium,
              color: Colors.orange,
              title: '技能认证',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.language,
              color: Colors.green,
              title: '个人主页',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.location_on,
              color: Colors.red,
              title: '我的工地',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.location_on,
              color: Colors.blue,
              title: '屏幕适配测试',
              onTap: () {
                NavigatorUtil.push(context, const ScreenPage());
              },
            ),
          ],
        ),
      ),
    );
  }
}
