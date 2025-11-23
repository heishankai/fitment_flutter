import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/components/loading_widget.dart';

/// H5 容器
class HiWebView extends StatefulWidget {
  final String url;
  final String? statusBarColor;
  final String? title;
  final bool? hideAppBar;
  final bool? backForbid;
  final void Function(String newUrl)? onUrlChanged;

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

  /// 需要拦截的 URL
  final List<String> _catchUrls = [
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

    /// Android 模拟器 localhost 自动替换为 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }

    /// http → https
    if (url.contains('zjiangyun.cn')) {
      url = url.replaceAll('http://', 'https://');
    }

    /// 添加 token
    _currentUrl = _addToken(url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) {
          _handleJSMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl!));
  }

  /// 添加 token 参数
  String _addToken(String urlStr) {
    try {
      Uri uri = Uri.parse(urlStr);
      String? token = LoginDao.getToken();

      if (token == null || uri.queryParameters.containsKey('token')) {
        return urlStr;
      }

      return uri.replace(
          queryParameters: {...uri.queryParameters, 'token': token}).toString();
    } catch (_) {
      return urlStr;
    }
  }

  /// 页面开始加载
  void _onPageStarted(String url) {
    _updateUrl(url);
    setState(() => _isLoading = true);
  }

  /// 页面加载完成
  void _onPageFinished(String url) {
    _updateUrl(url);
    _injectUserInfo();
    _injectFlutterLogoutBridge();
    _startUrlPolling(); // 单页应用 URL 变化监听
    setState(() => _isLoading = false);
  }

  /// 拦截导航请求
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    _updateUrl(request.url);

    /// 命中需要拦截的 URL → 返回 Flutter
    if (_catchUrls.any((u) => request.url.endsWith(u))) {
      NavigatorUtil.pop(context);
      return NavigationDecision.prevent;
    }

    /// token 自动补齐
    final token = LoginDao.getToken();
    if (token != null &&
        !Uri.parse(request.url).queryParameters.containsKey('token')) {
      _controller.loadRequest(Uri.parse(_addToken(request.url)));
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  /// 更新 URL + 回调
  void _updateUrl(String newUrl) {
    if (_currentUrl != newUrl) {
      _currentUrl = newUrl;
      widget.onUrlChanged?.call(newUrl);
    }
  }

  /// 注入用户信息到 localStorage
  void _injectUserInfo() async {
    try {
      final userInfo = LoginDao.getLocalUserInfo() ?? {};
      final jsonStr =
          jsonEncode(userInfo).replaceAll('\\', '\\\\').replaceAll("'", "\\'");
      await _controller.runJavaScript(
        "localStorage.setItem('userInfo', '$jsonStr');",
      );
    } catch (e) {
      debugPrint("❌ 注入用户信息失败: $e");
    }
  }

  /// JS 调用 Flutter 的消息处理
  void _handleJSMessage(String msg) {
    try {
      final data = jsonDecode(msg);
      if (data['action'] == 'logout') {
        _handleLogout();
      }
    } catch (e) {
      debugPrint("❌ 无效的 H5 消息: $msg");
    }
  }

  /// 退出登录
  void _handleLogout() {
    LoginDao.logout();
    if (context.mounted) NavigatorUtil.goToLogin();
  }

  /// 注入 JS → 提供 "window.AppLogout()" 给 H5 调用
  void _injectFlutterLogoutBridge() async {
    const js = '''
      window.AppLogout = function() {
        FlutterBridge.postMessage(JSON.stringify({ action: 'logout' }));
      };
    ''';

    try {
      await _controller.runJavaScript(js);
      debugPrint("✅ 注入 AppLogout 成功");
    } catch (e) {
      debugPrint("❌ 注入 AppLogout 失败: $e");
    }
  }

  /// SPA URL 轮询监听
  void _startUrlPolling() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    try {
      String result = await _controller
          .runJavaScriptReturningResult("window.location.href") as String;
      result = result.replaceAll('"', '');

      if (_currentUrl != result) {
        _updateUrl(result);
      }
    } catch (_) {}

    _startUrlPolling();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        Color(int.parse("0xff${widget.statusBarColor ?? 'ffffff'}"));
    final backColor =
        widget.statusBarColor == 'ffffff' ? Colors.black : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else if (context.mounted) {
          NavigatorUtil.pop(context);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            widget.hideAppBar == true
                ? Container(
                    color: statusColor,
                    height: MediaQuery.of(context).padding.top,
                  )
                : _buildAppBar(statusColor, backColor),
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
            child: Text(
              widget.title ?? '',
              style: TextStyle(color: backColor, fontSize: 20),
            ),
          )
        ],
      ),
    );
  }
}
