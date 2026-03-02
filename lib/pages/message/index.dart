import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/dao/chat_dao.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/config/h5_config.dart';
import 'package:intl/intl.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with AutomaticKeepAliveClientMixin, TabPageRefreshMixin<MessagePage> {
  List<Map<String, dynamic>> _msgList = [];
  bool _loading = true;
  int _systemUnread = 0;

  static const double _avatarSize = 48;
  static const double _cardRadius = 16;
  static const double _noticeRadius = 12;
  static const EdgeInsets _cardPadding = EdgeInsets.all(16);

  @override
  bool get wantKeepAlive => true;

  @override
  void onTabSelected() {
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ChatDao.getCraftsmanRooms(),
        ChatDao.getUnreadNotificationCount(),
      ]);

      if (!mounted) return;

      final roomsRes = results[0];
      final notificationRes = results[1];

      setState(() {
        _msgList = roomsRes['success'] == true && roomsRes['data'] is List
            ? List<Map<String, dynamic>>.from(roomsRes['data'])
            : [];
        _systemUnread = notificationRes['success'] == true &&
                notificationRes['data'] != null
            ? (notificationRes['data']['count'] ?? 0)
            : 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, '加载失败，请重试');
    }
  }

  Future<void> _onRefresh() async => _loadData();

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays == 0) return DateFormat('HH:mm').format(time);
      if (diff.inDays == 1) return '昨天 ${DateFormat('HH:mm').format(time)}';
      return DateFormat('MM-dd HH:mm').format(time);
    } catch (_) {
      return '';
    }
  }

  void _openH5(String path, String title) {
    final url = H5Config.getH5Url(path);
    NavigatorUtil.jumpH5(
      context: context,
      url: url,
      title: title,
      statusBarColor: '2d635e',
    );
  }

  void _handleClickMessage(Map<String, dynamic> item) async {
    final roomId = item['id'];
    final wechatUser = item['wechat_user'] as Map<String, dynamic>?;
    final wechatUserId = item['wechat_user_id'];
    final nickname = wechatUser?['nickname'] ?? '微信用户';
    if (roomId == null) return;

    await NavigatorUtil.jumpH5(
      context: context,
      url: H5Config.getH5Url(
        '/fitment-h5/chat/craftsman/$roomId?wechatUserId=$wechatUserId&wechatUserName=${Uri.encodeComponent(nickname)}',
      ),
      title: nickname,
      statusBarColor: '2d635e',
    );
    // 从聊天房间返回后刷新列表
    if (mounted) _loadData();
  }

  Widget _buildBadge(int count) {
    return Positioned(
      top: -6,
      right: -6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(minWidth: 18),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_noticeRadius),
          child: url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  width: _avatarSize,
                  height: _avatarSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                )
              : _buildDefaultAvatar(),
        ),
        if (unreadCount > 0) _buildBadge(unreadCount),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      color: Colors.grey[300],
      child: const Icon(Icons.person, color: Colors.grey),
    );
  }

  Widget _buildNoticeHeader() {
    final items = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': '系统通知',
        'color': AppColors.primary,
        'bg': AppColors.bgHover,
        'badge': _systemUnread,
        'onTap': () =>
            _openH5('/fitment-h5/notice/craftsman-system-message', '系统消息'),
      },
      {
        'icon': Icons.headset_mic_outlined,
        'title': '客服消息',
        'color': AppColors.error,
        'bg': AppColors.error.withOpacity(0.08),
        'onTap': () =>
            _openH5('/fitment-h5/admin-service/craftsman-msg', '客服消息'),
      },
      {
        'icon': Icons.campaign_outlined,
        'title': '平台公告',
        'color': AppColors.primary,
        'bg': AppColors.bgHover,
        'onTap': () =>
            _openH5('/fitment-h5/notice/notice-list?notice_type=2', '平台公告'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.bgGrey,
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildNoticeItem(
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    color: item['color'] as Color,
                    backgroundColor: item['bg'] as Color,
                    badge: item['badge'] as int?,
                    onTap: item['onTap'] as VoidCallback,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNoticeItem({
    required IconData icon,
    required String title,
    required Color color,
    required Color backgroundColor,
    int? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_noticeRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_noticeRadius),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(_noticeRadius),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badge != null && badge > 0) _buildBadge(badge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> item) {
    final wechatUser = item['wechat_user'] as Map<String, dynamic>?;
    final avatar = wechatUser?['avatar'] as String?;
    final nickname = wechatUser?['nickname'] as String? ?? '微信用户';
    final lastMessage = item['lastMessage'] as Map<String, dynamic>?;
    final content = lastMessage?['content'] as String? ?? '';
    final unreadCount = item['unreadCount'] as int? ?? 0;
    final timeStr =
        lastMessage?['createdAt'] as String? ?? item['updatedAt'] as String?;
    final time = _formatTime(timeStr);

    return InkWell(
      onTap: () => _handleClickMessage(item),
      borderRadius: BorderRadius.circular(_cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: _cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(avatar, unreadCount),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 昵称和时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (content.isNotEmpty)
                    Text(
                      content,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF646566)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Container(
          color: AppColors.bgHover,
          child: Column(
            children: [
              _buildNoticeHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: _loading && _msgList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _msgList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _msgList.length,
                              itemBuilder: (context, index) =>
                                  _buildMessageCard(_msgList[index]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
