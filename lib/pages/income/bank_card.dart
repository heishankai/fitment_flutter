import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:fitment_flutter/dao/wallet_dao.dart';
import 'package:fitment_flutter/utils/view_util.dart';

/// 银行卡页面
class BankCardPage extends StatefulWidget {
  const BankCardPage({super.key});

  @override
  State<BankCardPage> createState() => _BankCardPageState();
}

class _BankCardPageState extends State<BankCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _submitting = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNumberController.dispose();
    _bankBranchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await WalletDao.getBankCard();
      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'];
          _bankNameController.text = data['bank_name'] ?? '';
          _cardNumberController.text = data['card_number'] ?? '';
          _bankBranchController.text = data['bank_branch'] ?? '';
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isEdit = data['id'] != null;
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载银行卡信息失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToast(context, '加载失败，请重试');
      }
    }
  }

  /// 提交表单
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final data = {
        'bank_name': _bankNameController.text.trim(),
        'card_number': _cardNumberController.text.trim(),
        'bank_branch': _bankBranchController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      final result = _isEdit
          ? await WalletDao.updateBankCard(data: data)
          : await WalletDao.bindBankCard(data: data);

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context, true); // 返回 true 表示操作成功
        } else {
          showToast(context, result['message'] ?? '操作失败');
        }
      }
    } catch (e) {
      print('❌ 提交失败: $e');
      if (mounted) {
        showToast(context, '操作失败，请重试');
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
        title: const Text('银行卡'),
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
                    child: Form(
                      key: _formKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildFormField(
                              controller: _bankNameController,
                              label: '银行名称',
                              hintText: '请输入银行名称',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入银行名称';
                                }
                                return null;
                              },
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            _buildFormField(
                              controller: _cardNumberController,
                              label: '银行卡号',
                              hintText: '请输入银行卡号',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入银行卡号';
                                }
                                return null;
                              },
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            _buildFormField(
                              controller: _bankBranchController,
                              label: '开户行',
                              hintText: '请输入开户行',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入开户行';
                                }
                                return null;
                              },
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            _buildFormField(
                              controller: _nameController,
                              label: '姓名',
                              hintText: '请输入持卡人姓名',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入持卡人姓名';
                                }
                                return null;
                              },
                            ),
                            Divider(height: 1, color: Colors.grey.shade200),
                            _buildFormField(
                              controller: _phoneController,
                              label: '手机号',
                              hintText: '请输入手机号',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入手机号';
                                }
                                if (value.length != 11) {
                                  return '请输入正确的手机号';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
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
                    onPressed: _submitting ? null : _handleSubmit,
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
                        : Text(
                            _isEdit ? '更新银行卡' : '绑定银行卡',
                            style: const TextStyle(
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

  /// 构建表单字段
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                validator: validator,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDisable,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  errorStyle: const TextStyle(height: 0),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
