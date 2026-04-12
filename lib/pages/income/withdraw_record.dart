import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/dao/wallet_dao.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/utils/datetime_mainland.dart';

/// 提现记录页面
class WithdrawRecordPage extends StatefulWidget {
  const WithdrawRecordPage({super.key});

  @override
  State<WithdrawRecordPage> createState() => _WithdrawRecordPageState();
}

class _WithdrawRecordPageState extends State<WithdrawRecordPage> {
  List<dynamic> _withdrawRecords = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await WalletDao.getWithdrawRecord();
      if (mounted) {
        setState(() {
          if (result['success'] == true && result['data'] != null) {
            _withdrawRecords = result['data'] is List ? result['data'] : [];
          }
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('❌ 加载提现记录失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        showToast(context, '加载失败，请重试');
      }
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadData();
  }

  /// 格式化时间（固定东八区，不依赖系统时区）
  String _formatTime(dynamic time) => formatMainlandChinaDateTime(time);

  /// 格式化金额
  String _formatMoney(dynamic amount) {
    final num = double.tryParse(amount?.toString() ?? '0') ?? 0.0;
    return num.toStringAsFixed(2);
  }

  /// 获取状态文本
  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return '审核中';
      case 2:
        return '已完成';
      case 3:
        return '已拒绝';
      default:
        return '未知';
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.access_time; // 审核中
      case 2:
        return Icons.check_circle; // 已完成
      case 3:
        return Icons.cancel; // 已拒绝
      default:
        return Icons.help_outline;
    }
  }

  /// 获取状态颜色
  List<Color> _getStatusGradient(int status) {
    switch (status) {
      case 1:
        return [AppColors.warning, AppColors.warning.withOpacity(0.8)]; // 审核中
      case 2:
        return [AppColors.success, AppColors.success.withOpacity(0.8)]; // 已完成
      case 3:
        return [AppColors.error, AppColors.error.withOpacity(0.8)]; // 已拒绝
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提现记录'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _withdrawRecords.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _withdrawRecords.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '暂无提现记录',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _withdrawRecords.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final item = _withdrawRecords[index];
                        final status = item['status'] as int? ?? 0;
                        final amount = item['amount'] ?? 0;
                        final createdAt = item['createdAt'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // 状态图标
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _getStatusGradient(status),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 内容
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getStatusText(status),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 金额
                              Text(
                                '¥${_formatMoney(amount)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
