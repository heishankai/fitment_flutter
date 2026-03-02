import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';

/// 金额汇总卡片组件
class AmountSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? walletInfo;
  final VoidCallback? onWithdraw;

  const AmountSummaryCard({
    super.key,
    this.walletInfo,
    this.onWithdraw,
  });

  /// 金额格式化 & 防御性处理
  String _formatMoney(dynamic val) {
    final num = double.tryParse(val?.toString() ?? '0') ?? 0.0;
    return num.toStringAsFixed(2);
  }

  /// 计算总余额（余额 + 质保金）
  String get _totalBalance {
    final balance = double.tryParse(walletInfo?['balance']?.toString() ?? '0') ?? 0.0;
    final freezeMoney = double.tryParse(walletInfo?['freeze_money']?.toString() ?? '0') ?? 0.0;
    return _formatMoney(balance + freezeMoney);
  }

  /// 可提现金额
  String get _withdrawableBalance {
    return _formatMoney(walletInfo?['balance'] ?? 0);
  }

  /// 质保金
  String get _freezeMoney {
    return _formatMoney(walletInfo?['freeze_money'] ?? 0);
  }

  /// 是否可以提现
  bool get _canWithdraw {
    final balance = double.tryParse(walletInfo?['balance']?.toString() ?? '0') ?? 0.0;
    return balance > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '我的钱包',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // 金额区块
          Row(
            children: [
              // 余额
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '余额',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥$_totalBalance',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 分隔线
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.2),
              ),

              // 质保金
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '质保金',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥$_freezeMoney',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 12),

          // 可提现区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '可提现',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥$_withdrawableBalance',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _canWithdraw ? onWithdraw : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.white.withOpacity(0.15);
                    }
                    return Colors.white.withOpacity(0.25);
                  }),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '提现',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 6),

          // 底部提示
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 12,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                '质保金将用于用户售后质量保障',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
