import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:fitment_flutter/dao/wallet_dao.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/pages/income/bank_card.dart';

/// 提现页面
class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  Map<String, dynamic>? _walletInfo;
  Map<String, dynamic>? _bankCardInfo;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        WalletDao.getWalletInfo(),
        WalletDao.getBankCard(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] == true && results[0]['data'] != null) {
            _walletInfo = results[0]['data'];
          }
          if (results[1]['success'] == true && results[1]['data'] != null) {
            _bankCardInfo = results[1]['data'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载数据失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToast(context, '加载失败，请重试');
      }
    }
  }

  /// 获取可提现金额
  double get _availableBalance {
    final balance = _walletInfo?['balance'];
    return double.tryParse(balance?.toString() ?? '0') ?? 0.0;
  }

  /// 格式化金额显示
  String _formatBalance() {
    return _availableBalance.toStringAsFixed(2);
  }

  /// 获取快速金额选项
  List<dynamic> get _quickAmounts {
    final amount = _availableBalance;
    if (amount < 100) return [];
    final List<dynamic> amounts = [];
    if (amount >= 100) amounts.add(100);
    if (amount >= 500) amounts.add(500);
    if (amount >= 1000) amounts.add(1000);
    amounts.add('all');
    return amounts;
  }

  /// 设置快速金额
  void _setQuickAmount(dynamic amount) {
    if (amount == 'all') {
      _amountController.text = _formatBalance();
    } else {
      _amountController.text = amount.toString();
    }
    // 仅改 Controller 不会触发 build，需刷新以更新「确认提现」按钮状态
    if (mounted) setState(() {});
  }

  /// 处理金额输入
  void _handleAmountInput(String value) {
    final inputAmount = double.tryParse(value) ?? 0.0;
    if (inputAmount > _availableBalance) {
      _amountController.text = _formatBalance();
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
      showToast(context, '提现金额不能超过可提现金额');
    }
    if (mounted) setState(() {});
  }

  /// 格式化银行卡号
  String _formatBankCard(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) return '';
    if (cardNumber.length <= 4) return cardNumber;
    return '****${cardNumber.substring(cardNumber.length - 4)}';
  }

  /// 是否可以提交
  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount > 0 &&
        amount <= _availableBalance &&
        _bankCardInfo?['card_number'] != null &&
        !_submitting;
  }

  /// 跳转到银行卡页面
  Future<void> _goToBankCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BankCardPage(),
      ),
    );
    // 如果从银行卡页面返回，重新加载数据
    if (result == true) {
      _loadData();
    }
  }

  /// 提交提现
  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      showToast(context, '请输入提现金额');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final result = await WalletDao.applyWithdraw(amount: amount);
      if (mounted) {
        if (result['success'] == true) {
          showToast(context, '提现申请成功');
          Navigator.pop(context);
        } else {
          showToast(context, result['message'] ?? '申请提现失败');
        }
      }
    } catch (e) {
      print('❌ 申请提现失败: $e');
      if (mounted) {
        showToast(context, '申请提现失败，请重试');
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提现'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 可提现金额卡片
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryGradientEnd
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '可提现金额',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '¥${_formatBalance()}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 提现金额输入
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '提现金额',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text(
                                    '¥',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '请输入提现金额',
                                        hintStyle: TextStyle(
                                          fontSize: 28,
                                          color: AppColors.textDisable,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: _handleAmountInput,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 2,
                                color: AppColors.bgGrey,
                                margin: const EdgeInsets.only(bottom: 16),
                              ),
                              // 快速金额选项
                              if (_quickAmounts.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _quickAmounts.map((amount) {
                                    return InkWell(
                                      onTap: () => _setQuickAmount(amount),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.bgGrey,
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          amount == 'all' ? '全部' : '¥$amount',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 银行卡信息卡片
                        InkWell(
                          onTap: _goToBankCard,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '提现到',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.textGrey,
                                    ),
                                  ],
                                ),
                                if (_bankCardInfo?['card_number'] != null) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _bankCardInfo?['bank_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatBankCard(
                                              _bankCardInfo?['card_number']),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '请先绑定银行卡',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 提现说明
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.textGrey,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• 每周发起一次提现，周五统一到账',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                        height: 1.8,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '• 20000元以内提现有0.5%（千分之五），20000以上提现免手续费',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                        height: 1.8,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '• 平台不额外收取押金，质保金用于保证售后，这笔钱在最后一单保修期满才可提现',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                        height: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 提交按钮
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '确认提现',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
