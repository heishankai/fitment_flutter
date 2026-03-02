import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/utils/view_util.dart';
import 'package:fitment_flutter/components/input_widget.dart';
import 'dart:async';
import 'package:fitment_flutter/utils/navigator_util.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loginDisabled = false;
  bool _isLoadingVerifyCode = false; // 获取验证码加载状态
  String? phone;
  String? verifyCode;
  int _countdown = 0;
  Timer? _timer;
  final FocusNode _verifyCodeFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false, // 输入框获焦时页面不上移
        body: Stack(
          children: [
            ..._background(),
            _content(),
          ],
        ));
  }

  List<Widget> _background() {
    return [
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft, // 135deg 从左下到右上
              end: Alignment.topRight,
              stops: [0.0, 1.0],
              colors: [
                AppColors.primary,
                AppColors.primaryGradientEnd,
              ],
            ),
          ),
        ),
      )
    ];
  }

  Widget _content() {
    return Positioned(
      left: 24,
      right: 24,
      top: 0,
      bottom: 0,
      child: ListView(
        controller: _scrollController,
        children: [
          hiSpace(height: 100),
          const Text('欢迎登录叮当师傅',
              style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          hiSpace(height: 12),
          const Text('请输入手机号获取验证码',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          hiSpace(height: 70),
          InputWidget(
            hint: '请输入手机号码',
            maxLength: 11,
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              phone = value.trim(); // 去除空格
            },
          ),
          hiSpace(height: 20),
          InputWidget(
            hint: '请输入验证码',
            maxLength: 4,
            keyboardType: TextInputType.number,
            controller: _verifyCodeController,
            focusNode: _verifyCodeFocusNode,
            onChanged: (value) {
              verifyCode = value.trim(); // 去除空格
              // 当验证码长度不是4位时，重置登录状态，允许重新登录

              if (value.length != 4) {
                setState(() {
                  loginDisabled = false;
                });
                return;
              }

              _onLogin(context);
            },
          ),
          hiSpace(height: 50),
          _buildVerifyCodeButton(),
        ],
      ),
    );
  }

  /// 构建获取验证码按钮
  Widget _buildVerifyCodeButton() {
    final bool isEnabled = _countdown == 0 && !_isLoadingVerifyCode;
    
    return GestureDetector(
      onTap: isEnabled ? _onGetVerifyCode : null,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 1.0],
                  colors: [
                    AppColors.primary,
                    AppColors.primaryGradientEnd,
                  ],
                )
              : null,
          color: isEnabled ? null : AppColors.textDisable,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: _isLoadingVerifyCode
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _countdown > 0 ? '$_countdown秒后重新获取' : '获取验证码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? AppColors.textInverse : AppColors.textGrey,
                ),
              ),
      ),
    );
  }

  /// 获取验证码
  void _onGetVerifyCode() async {
    // 直接从 controller 获取值，确保获取到最新的输入
    String phoneValue = _phoneController.text.trim();

    // 改进验证逻辑：检查手机号是否为空或长度不等于 11
    if (phoneValue.isEmpty || phoneValue.length != 11) {
      print('手机号验证失败: phone=$phoneValue, length=${phoneValue.length}');
      showToast(context, '请输入正确的手机号码');
      return;
    }

    // 更新 phone 变量
    phone = phoneValue;

    if (_countdown != 0 || _isLoadingVerifyCode) return;

    // 使用微任务立即更新UI，提供最快的视觉反馈
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isLoadingVerifyCode = true;
        });
      }
    });

    // 调用 API 获取验证码
    try {
      final result = await LoginDao.getSmsCode(phone: phoneValue);

      if (result['success'] == true) {
        // 成功获取验证码，开始倒计时
        _startCountdown();
        if (mounted) {
          showToast(context, result['message'] ?? '验证码发送成功');
          // 让验证码输入框获取焦点
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _verifyCodeFocusNode.requestFocus();
            }
          });
        }
      } else {
        // 获取验证码失败
        if (mounted) {
          String errorMessage = result['message'] ?? '获取验证码失败，请稍后重试';
          showToast(context, errorMessage);
        }
      }
    } catch (e) {
      print('获取验证码异常: $e');
      if (mounted) {
        showToast(context, '获取验证码失败，请稍后重试');
      }
    } finally {
      // 无论成功还是失败，都要重置加载状态
      if (mounted) {
        setState(() {
          _isLoadingVerifyCode = false;
        });
      }
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// 登录
  void _onLogin(context) async {
    // 直接从 controller 获取值，确保获取到最新的输入
    String phoneValue = _phoneController.text.trim();
    String verifyCodeValue = _verifyCodeController.text.trim();

    if (phoneValue.isEmpty || phoneValue.length != 11) {
      showToast(context, '请输入正确的手机号码');
      return;
    }
    if (verifyCodeValue.isEmpty || verifyCodeValue.length != 4) {
      showToast(context, '请输入验证码');
      return;
    }
    if (loginDisabled) return;

    // 更新变量
    phone = phoneValue;
    verifyCode = verifyCodeValue;

    // 显示加载状态
    setState(() {
      loginDisabled = true;
    });

    try {
      final result = await LoginDao.Login(
        phone: phoneValue,
        verifyCode: verifyCodeValue,
      );

      // 检查登录结果
      if (result['success'] == true || result['code'] == 200) {
        // 登录成功
        showToast(context, '登录成功');
        
        // 清空输入框和状态
        setState(() {
          loginDisabled = false;
          phone = null;
          verifyCode = null;
          _countdown = 0;
          _phoneController.clear();
          _verifyCodeController.clear();
        });

        _timer?.cancel();
        _verifyCodeFocusNode.unfocus();

        // 跳转到首页
        NavigatorUtil.goToHome(context);
      } else {
        // 登录失败
        String errorMessage = result['message'] ?? '登录失败，请稍后重试';
        showToast(context, errorMessage);
        
        // 重置登录状态，允许重新登录
        setState(() {
          loginDisabled = false;
        });
      }
    } catch (e) {
      print('登录异常: $e');
      showToast(context, '登录失败，请稍后重试');
      
      // 重置登录状态
      setState(() {
        loginDisabled = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _verifyCodeController.dispose();
    _phoneFocusNode.dispose();
    _verifyCodeFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
