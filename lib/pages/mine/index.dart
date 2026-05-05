import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/dao/user_dao.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/config/h5_config.dart';
import 'package:fitment_flutter/pages/mine/edit_info.dart';
import 'package:fitment_flutter/pages/mine/service_standards_page.dart';
import 'package:fitment_flutter/components/loading_widget.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage>
    with AutomaticKeepAliveClientMixin, TabPageRefreshMixin<MinePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  void onTabSelected() {
    _loadUserInfo();
  }

  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    final result = await UserDao.getUserInfo();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          _userInfo = result['data'] as Map<String, dynamic>;
        }
      });
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadUserInfo();
  }

  /// 打开 WebView
  void _openWebView(String path, {String? title, Map<String, String>? query}) {
    var url = H5Config.getH5Url(path);
    if (query != null && query.isNotEmpty) {
      final queryString = query.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$queryString';
    }
    NavigatorUtil.jumpH5(
      context: context,
      url: url,
      title: title ?? '',
      statusBarColor: '2d635e',
    );
  }

  /// 跳转到编辑资料页面
  void _goToEditInfo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditInfoPage(),
      ),
    );
    // 如果返回成功，刷新用户信息
    if (result == true) {
      _loadUserInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Container(
          color: AppColors.bgGrey,
          child: LoadingWidget(
            isLoading: _isLoading,
            cover: true,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 顶部间距
                    const SizedBox(height: 16),
                    // 用户卡片
                    _buildUserCard(),
                    // 菜单列表
                    _buildMenuList(),
                    // 底部间距
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建用户卡片
  Widget _buildUserCard() {
    final nickname = _userInfo?['nickname'] ?? '未设置昵称';
    final avatar = _userInfo?['avatar'] as String?;
    final isVerified = _userInfo?['isVerified'] == true;
    final isSkillVerified = _userInfo?['isSkillVerified'] == true;
    final completedOrdersCount = _userInfo?['completedOrdersCount'] ?? 0;
    // 处理 score 可能是 int 或 double 的情况
    final scoreValue = _userInfo?['score'];
    final score = scoreValue is int
        ? scoreValue.toDouble()
        : (scoreValue is double ? scoreValue : 0.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像和昵称区域
          _buildProfileSection(nickname, avatar, isVerified, isSkillVerified),
          const SizedBox(height: 20),
          // 统计数据
          _buildStats(completedOrdersCount, score),
          const SizedBox(height: 20),
          // 编辑资料按钮
          _buildEditButton(),
        ],
      ),
    );
  }

  /// 构建头像和昵称区域
  Widget _buildProfileSection(
    String nickname,
    String? avatar,
    bool isVerified,
    bool isSkillVerified,
  ) {
    return Row(
      children: [
        // 头像
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: avatar != null && avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatar,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            '👤',
                            style: TextStyle(fontSize: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Text(
                      '👤',
                      style: TextStyle(fontSize: 40, color: Colors.grey),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        // 昵称和标签
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(
                    isVerified ? '已实名' : '未实名认证',
                    isVerified,
                    AppColors.primary,
                  ),
                  _buildBadge(
                    isSkillVerified ? '技能认证通过' : '技能未认证',
                    isSkillVerified,
                    AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建标签
  Widget _buildBadge(String text, bool isVerified, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified)
            Icon(
              Icons.check,
              size: 14,
              color: color,
            ),
          if (isVerified) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据
  Widget _buildStats(int completedOrdersCount, double score) {
    // score 显示为整数（如果本身就是整数）
    final scoreDisplay = score == score.roundToDouble()
        ? score.toInt().toString()
        : score.toString();

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                '$completedOrdersCount',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '已完成订单',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 50,
          color: AppColors.border,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                scoreDisplay,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '综合评分',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建编辑资料按钮
  Widget _buildEditButton() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2D635E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D635E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToEditInfo,
          borderRadius: BorderRadius.circular(24),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '编辑资料',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建菜单列表
  Widget _buildMenuList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.verified_user,
            color: AppColors.primary,
            title: '实名认证',
            onTap: () =>
                _openWebView('/fitment-h5/mine/real-name-auth', title: '实名认证'),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.workspace_premium,
            color: AppColors.warning,
            title: '技能认证',
            onTap: () =>
                _openWebView('/fitment-h5/mine/skill-auth', title: '技能认证'),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.person,
            color: AppColors.success,
            title: '个人主页',
            onTap: () => _openWebView('/fitment-h5/mine/personal-homepage',
                title: '个人主页'),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.location_on,
            color: AppColors.error,
            title: '我的工地订单',
            onTap: () => _openWebView('/fitment-h5/mine/my-construction',
                title: '我的工地订单'),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.menu_book_outlined,
            color: AppColors.primary,
            title: '服务规范',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceStandardsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // color + '22' 表示颜色值加上透明度 22 (0x22 = 34/255 ≈ 0.13)
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDisable,
            ),
          ],
        ),
      ),
    );
  }
}
