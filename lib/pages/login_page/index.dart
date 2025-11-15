import 'package:fitment_flutter/components/button_widget.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:flutter/material.dart';
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
  String? phone;
  String? verifyCode;
  int _countdown = 0;
  Timer? _timer;
  final FocusNode _verifyCodeFocusNode = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false, // 避免内容被键盘遮挡
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
                Color(0xFF00CEC9), // #00cec9
                Color(0xFF00B4D8), // #00b4d8
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
        children: [
          hiSpace(height: 100),
          const Text('欢迎登录叮当优+',
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
          ButtonWidget(
            title: _countdown > 0 ? '$_countdown秒后重新获取' : '获取验证码',
            onPressed: () => _onGetVerifyCode(),
            enable: _countdown == 0,
          ),
        ],
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

    if (_countdown != 0) return;

    // 调用 API 获取验证码
    try {
      final result = await LoginDao.getSmsCode(phone: phoneValue);

      if (result['success'] == true) {
        // 成功获取验证码，开始倒计时
        _startCountdown();
        showToast(context, result['message'] ?? '验证码发送成功');
        // 让验证码输入框获取焦点
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyCodeFocusNode.requestFocus();
        });
      } else {
        // 获取验证码失败
        String errorMessage = result['message'] ?? '获取验证码失败，请稍后重试';
        showToast(context, errorMessage);
      }
    } catch (e) {
      print('获取验证码异常: $e');
      showToast(context, '获取验证码失败，请稍后重试');
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

    final result = await LoginDao.Login(phone: phone!, verifyCode: verifyCode!);

    // if (result['success'] == !true) {
    //   showToast(context, result['message'] ?? '登录失败');
    //   return;
    // }

    setState(() {
      loginDisabled = true;
      phone = null;
      verifyCode = null;
      _countdown = 0;
    });

    _timer?.cancel();
    _verifyCodeFocusNode.unfocus();

    NavigatorUtil.goToHome(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _verifyCodeController.dispose();
    _verifyCodeFocusNode.dispose();
    super.dispose();
  }
}
