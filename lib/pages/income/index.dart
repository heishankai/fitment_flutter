import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/dao/wallet_dao.dart';
import 'package:fitment_flutter/components/amount_summary_card.dart';
import 'package:fitment_flutter/components/account_details.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/pages/income/withdraw.dart';
import 'package:fitment_flutter/pages/income/bank_card.dart';
import 'package:fitment_flutter/pages/income/withdraw_record.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';

/// 收入页面
class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage>
    with AutomaticKeepAliveClientMixin, TabPageRefreshMixin<IncomePage> {
  Map<String, dynamic>? _walletInfo;
  List<dynamic> _accountDetails = [];
  bool _loading = true;
  bool _hasInitialized = false; // 标记是否已经初始化过

  @override
  bool get wantKeepAlive => true;

  @override
  void onTabSelected() {
    _fetchData();
  }

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _fetchData();
    }
  }

  /// 拉取钱包 & 明细
  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        WalletDao.getWalletInfo(),
        WalletDao.getWalletTransaction(),
      ]);

      if (!mounted) return;

      final walletRes = results[0];
      final detailRes = results[1];

      setState(() {
        _walletInfo =
            walletRes['success'] == true ? walletRes['data'] : _walletInfo;

        _accountDetails =
            detailRes['success'] == true && detailRes['data'] is List
                ? detailRes['data']
                : [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showToast(context, '加载失败，请重试');
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _fetchData();
  }

  /// 提现
  Future<void> _handleWithdraw() async {
    final balance =
        double.tryParse(_walletInfo?['balance']?.toString() ?? '0') ?? 0;

    if (balance <= 0) {
      showToast(context, '可提现金额为0');
      return;
    }

    final bankCardRes = await WalletDao.getBankCard();
    final bankCard = bankCardRes['data'];

    if (bankCard == null || bankCard['card_number'] == null) {
      showToast(context, '请先绑定银行卡');
      _goToBankCard();
      return;
    }

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WithdrawPage()),
    );

    if (success == true) {
      _fetchData();
    }
  }

  void _goToWithdrawRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WithdrawRecordPage()),
    );
  }

  Future<void> _goToBankCard() async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BankCardPage()),
    );

    if (success == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.white,
          child: _loading && _walletInfo == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AmountSummaryCard(
                                  walletInfo: _walletInfo,
                                  onWithdraw: _handleWithdraw,
                                ),
                                _buildMenu(),
                                AccountDetails(details: _accountDetails),
                                const Spacer(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  /// 功能菜单
  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.receipt_long,
            title: '提现记录',
            color: AppColors.warning,
            onTap: _goToWithdrawRecord,
          ),
          const SizedBox(height: 6),
          _menuItem(
            icon: Icons.credit_card,
            title: '银行卡',
            color: AppColors.success,
            onTap: _goToBankCard,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
