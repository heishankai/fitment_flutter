import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';

/// 订单弹窗组件（优化稳定版）
class OrderPopup extends StatefulWidget {
  final bool show;
  final Map<String, dynamic>? order;
  final double distance;
  final Function(int orderId) onGrabOrder;
  final VoidCallback onClose;

  const OrderPopup({
    super.key,
    required this.show,
    this.order,
    required this.distance,
    required this.onGrabOrder,
    required this.onClose,
  });

  @override
  State<OrderPopup> createState() => _OrderPopupState();
}

class _OrderPopupState extends State<OrderPopup> {
  bool _submitting = false;

  // ====================== Utils ======================

  String _safeText(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }

  String _encryptPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    if (phone.length < 11) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(7)}';
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays == 0) {
        return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      return '${time.month}-${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  void _handleGrab() async {
    if (_submitting || widget.order == null) return;

    setState(() {
      _submitting = true;
    });

    try {
      widget.onGrabOrder(widget.order!['id']);
    } finally {
      // 是否关闭由外部控制，这里只负责防抖
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _submitting = false;
          });
        }
      });
    }
  }

  // ====================== Build ======================

  @override
  Widget build(BuildContext context) {
    if (!widget.show || widget.order == null) {
      return const SizedBox.shrink();
    }

    final order = widget.order!;
    final safeTop = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: safeTop,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85 - safeTop,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: '订单信息',
                        icon: Icons.receipt_long,
                        children: [
                          _buildInfoRow('订单ID', _safeText(order['id'])),
                          _buildInfoRow(
                              '工种', _safeText(order['work_kind_name'])),
                          _buildInfoRow(
                            '位置',
                            _safeText(order['location']).isNotEmpty
                                ? _safeText(order['location'])
                                : '${_safeText(order['province'])} ${_safeText(order['city'])} ${_safeText(order['district'])}',
                          ),
                          _buildInfoRow(
                              '距离', '${widget.distance.toStringAsFixed(2)} km'),
                          _buildInfoRow('房屋类型',
                              order['houseType'] == 'new' ? '新房' : '老房'),
                          _buildInfoRow('户型', _safeText(order['roomType'])),
                          _buildInfoRow('面积', '${_safeText(order['area'])} m²'),
                          if (_safeText(order['description']).isNotEmpty)
                            _buildInfoRow(
                                '描述', _safeText(order['description'])),
                          if (_safeText(order['budget']).isNotEmpty)
                            _buildInfoRow(
                                '预算', '${_safeText(order['budget'])} 元'),
                          if (_safeText(order['createdAt']).isNotEmpty)
                            _buildInfoRow('创建时间',
                                _formatTime(_safeText(order['createdAt']))),
                        ],
                      ),
                      if (order['wechat_user'] != null) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          title: '用户信息',
                          icon: Icons.person_outline,
                          children: [
                            _buildUserInfo(
                                order['wechat_user'] as Map<String, dynamic>),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== Widgets ======================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '新订单来了',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(Map<String, dynamic> user) {
    final avatar = _safeText(user['avatar']);
    final hasAvatar = avatar.isNotEmpty && avatar.toLowerCase() != 'null';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: ClipOval(
            child: hasAvatar
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.grey),
                  )
                : const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _safeText(user['nickname']).isEmpty
                    ? '用户'
                    : _safeText(user['nickname']),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              if (_safeText(user['phone']).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _encryptPhone(_safeText(user['phone'])),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
          color: AppColors.bgGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _submitting ? null : _handleGrab,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  '立即抢单',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}
