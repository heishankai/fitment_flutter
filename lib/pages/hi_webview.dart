import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/components/loading_widget.dart';
import 'package:fitment_flutter/pages/login_page/index.dart';

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
      ..setJavaScriptMode(
          JavaScriptMode.unrestricted) // 启用 JavaScript，支持地理位置 API
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
          // 注意：地理位置权限处理由 webview_flutter 插件自动处理
          // 权限已在 AndroidManifest.xml 和 Info.plist 中声明
          // 当 H5 页面调用 navigator.geolocation API 时，系统会自动弹出权限请求对话框
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

  /// JS 调用 Flutter 的消息处理
  void _handleJSMessage(String msg) {
    try {
      debugPrint("📨 收到 H5 消息: $msg");
      // 尝试解析 JSON
      dynamic data;
      if (msg.startsWith('{') || msg.startsWith('[')) {
        // 看起来是 JSON 字符串，直接解析
        data = jsonDecode(msg);
      } else {
        // 可能已经被解析过了，或者是其他格式
        debugPrint("⚠️ 消息格式不是 JSON，尝试直接处理");
        return;
      }
      
      if (data is Map && data['action'] == 'logout') {
        debugPrint("✅ 处理退出登录请求");
        _handleLogout();
      } else {
        debugPrint("⚠️ 未知的 action: ${data['action']}");
      }
    } catch (e) {
      debugPrint("❌ 解析 H5 消息失败: $e");
      debugPrint("   消息内容: $msg");
      debugPrint("   消息类型: ${msg.runtimeType}");
    }
  }

  /// 退出登录
  void _handleLogout() {
    LoginDao.logout();
    if (context.mounted) {
      // 使用当前 context 跳转到登录页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
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
