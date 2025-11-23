import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/components/loading_widget.dart';

/// H5 容器
/// 支持：
/// 1. token 自动注入
/// 2. SPA 单页应用路由变化监听（轮询方式）
/// 3. 自定义 AppBar / 隐藏 AppBar
/// 4. 拦截特定 URL 返回 Flutter 页面
/// 5. 后退按钮处理
class HiWebView extends StatefulWidget {
  final String url; // 初始 URL
  final String? statusBarColor; // 状态栏颜色
  final String? title; // AppBar 标题
  final bool? hideAppBar; // 是否隐藏 AppBar
  final bool? backForbid; // 是否禁止 H5 返回
  final void Function(String newUrl)? onUrlChanged; // URL 变化回调

  const HiWebView({
    super.key,
    required this.url,
    this.statusBarColor,
    this.title,
    this.hideAppBar,
    this.backForbid,
    this.onUrlChanged,
  });

  @override
  State<HiWebView> createState() => _HiWebViewState();
}

class _HiWebViewState extends State<HiWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  /// 需要拦截的 URL 列表
  final List<String> _catchUrls = [
    'https://www.baidu.com',
    'https://www.zjiangyun.cn',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// 初始化 WebView
  void _initWebView() {
    String url = widget.url;

    // Android 模拟器 localhost 替换为 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }

    // 特定域名 http 改为 https
    if (url.contains('zjiangyun.cn')) {
      url = url.replaceAll('http://', 'https://');
    }

    // 添加 token
    _currentUrl = _addTokenToUrl(url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl!));
  }

  /// 给 URL 添加 token 参数
  String _addTokenToUrl(String urlString) {
    try {
      Uri uri = Uri.parse(urlString);
      final token = LoginDao.getToken();
      if (token == null || uri.queryParameters.containsKey('token'))
        return urlString;
      final newUri = uri
          .replace(queryParameters: {...uri.queryParameters, 'token': token});
      return newUri.toString();
    } catch (_) {
      return urlString;
    }
  }

  /// 页面开始加载
  void _onPageStarted(String url) {
    _updateUrl(url);
    _injectUserInfo();
    setState(() => _isLoading = true);
  }

  /// 页面加载完成
  void _onPageFinished(String url) {
    _updateUrl(url);
    _injectUserInfo();
    _startUrlPolling(); // SPA 单页应用路由变化轮询
    setState(() => _isLoading = false);
  }

  /// 拦截导航请求
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    _updateUrl(request.url);

    // 拦截特定 URL 返回 Flutter
    if (_catchUrls.any((u) => request.url.endsWith(u))) {
      NavigatorUtil.pop(context);
      return NavigationDecision.prevent;
    }

    // token 注入
    final token = LoginDao.getToken();
    if (token != null &&
        !Uri.parse(request.url).queryParameters.containsKey('token')) {
      _controller.loadRequest(Uri.parse(_addTokenToUrl(request.url)));
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// 更新当前 URL 并触发回调
  void _updateUrl(String newUrl) {
    if (_currentUrl != newUrl) {
      _currentUrl = newUrl;
      widget.onUrlChanged?.call(newUrl);
    } else if (_currentUrl == null) {
      _currentUrl = newUrl;
      widget.onUrlChanged?.call(newUrl);
    }
  }

  /// 注入用户信息到 localStorage
  void _injectUserInfo() async {
    final userInfo = LoginDao.getLocalUserInfo() ?? {};
    final jsonStr =
        jsonEncode(userInfo).replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    await _controller
        .runJavaScript("localStorage.setItem('userInfo', '$jsonStr');");
  }

  /// SPA 单页应用 URL 轮询监听
  void _startUrlPolling() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    try {
      final result = await _controller
          .runJavaScriptReturningResult('window.location.href') as String?;
      if (result != null) {
        final currentUrl = result.replaceAll('"', '').replaceAll("'", '');
        if (_currentUrl != currentUrl) {
          _updateUrl(currentUrl);
        }
      }
    } catch (_) {}

    // 持续轮询
    _startUrlPolling();
  }

  /// Android / Flutter 返回处理
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarColor =
        Color(int.parse('0xff${widget.statusBarColor ?? 'ffffff'}'));
    final backButtonColor =
        widget.statusBarColor == 'ffffff' ? Colors.black : Colors.white;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Column(
          children: [
            widget.hideAppBar == true
                ? Container(
                    color: statusBarColor,
                    height: MediaQuery.of(context).padding.top)
                : _buildAppBar(statusBarColor, backButtonColor),
            Expanded(
              child: LoadingWidget(
                isLoading: _isLoading,
                cover: true,
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 AppBar
  Widget _buildAppBar(Color bgColor, Color backColor) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: bgColor,
      padding: EdgeInsets.fromLTRB(0, top, 0, 10),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            child: GestureDetector(
              onTap: () async {
                if (await _controller.canGoBack()) {
                  _controller.goBack();
                } else if (context.mounted) {
                  NavigatorUtil.pop(context);
                }
              },
              child: Icon(Icons.arrow_back, color: backColor, size: 26),
            ),
          ),
          Center(
              child: Text(widget.title ?? '',
                  style: TextStyle(color: backColor, fontSize: 20))),
        ],
      ),
    );
  }
}
