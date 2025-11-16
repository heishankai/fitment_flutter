import 'dart:io';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// H5容器
class HiWebView extends StatefulWidget {
  /// 网页地址
  final String? url;

  /// 状态栏颜色
  final String? statusBarColor;

  /// 标题
  final String? title;

  /// 是否隐藏AppBar
  final bool? hideAppBar;

  /// 禁止我的页面返回按钮
  final bool? backForbid;

  const HiWebView(
      {super.key,
      required this.url,
      this.statusBarColor,
      this.title,
      this.hideAppBar,
      this.backForbid});

  @override
  State<HiWebView> createState() => _HiWebViewState();
}

class _HiWebViewState extends State<HiWebView> {
  /// 需要拦截的URL (跳出H5页面，返回flutter页面)
  final List<String> _catchUrls = [
    'https://www.baidu.com',
    'https://www.zjiangyun.cn',
  ];

  String? url;
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    url = widget.url;

    if (url != null) {
      // Android 模拟器需要使用 10.0.2.2 访问宿主机
      if (Platform.isAndroid && url!.contains('localhost')) {
        url = url!.replaceAll('localhost', '10.0.2.2');
        print('🔄 [Android 模拟器] 将 localhost 转换为 10.0.2.2: $url');
      }

      if (url!.contains('zjiangyun.cn')) {
        /// http 无法打开 改为https
        url = url!.replaceAll('http://', 'https://');
      }
    }
    _initWebViewController();
  }

  /// 初始化 WebViewController 实例
  /// 设置 JavaScript 模式为 unrestricted，允许执行 JavaScript 代码，..表示初始化就执行

  void _initWebViewController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            /// 页面加载进度
            print('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            /// 页面加载开始
            print('WebView is loading: $url');
          },
          onPageFinished: (String url) {
            /// 页面加载完成
            _handleBackForbid();
          },
          onWebResourceError: (WebResourceError error) {
            /// 页面加载错误
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) async {
            debugPrint('WebView navigation request: ${request}');

            /// 解析URL
            var uri = Uri.parse(request.url);
            var name = uri.queryParameters['name'];
            var age = uri.queryParameters['age'];

            print('WebView navigation request: ${request.url}');
            // print('WebView navigation request: ${name}');
            // print('WebView navigation request: ${age}');

            /// 显示参数
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('name: ${name}, age: ${age}'),
            //   ),
            // );

            if (_isToMain(request.url)) {
              /// 拦截URL，返回flutter页面
              NavigatorUtil.pop(context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url!));
  }

  /// 判断 H5 URL 是否返回主页
  bool _isToMain(String url) {
    bool contain = false;

    for (var item in _catchUrls) {
      if (url.endsWith(item)) {
        contain = true;
        break;
      }
    }

    return contain;
  }

  void _handleBackForbid() {
    if (widget.backForbid == true) {
      controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusBarColorStr = widget.statusBarColor ?? 'ffffff';
    Color backButtonColor;

    if (statusBarColorStr == 'ffffff') {
      backButtonColor = Colors.black;
    } else {
      backButtonColor = Colors.white;
    }

    /// 处理安卓物理返回键，禁止返回flutter的上一页
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (await controller.canGoBack()) {
            /// 返回H5的上一页
            controller.goBack();
          } else {
            /// 返回flutter的上一页
            if (context.mounted) NavigatorUtil.pop(context);
          }
        },
        child: Scaffold(
            body: Column(
          children: [
            _appBar(
                Color(int.parse('0xff$statusBarColorStr')), backButtonColor),
            Expanded(child: WebViewWidget(controller: controller)),
          ],
        )));
  }

  Widget _appBar(Color backgroundColor, Color backButtonColor) {
    /// 获取留海屏顶部的安全间距
    double top = MediaQuery.of(context).padding.top;

    /// 如果隐藏AppBar，则返回一个容器，高度为留海屏顶部的安全间距
    if (widget.hideAppBar ?? false) {
      return Container(
        color: backgroundColor,
        height: top,
      );
    }

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.fromLTRB(0, top, 0, 10),
      child: FractionallySizedBox(
          widthFactor: 1, // 宽度占满父容器
          child: Stack(
            children: [
              _backButton(backButtonColor),
              _title(backButtonColor),
            ],
          )),
    );
  }

  /// 返回按钮
  Widget _backButton(Color backButtonColor) {
    return GestureDetector(
      onTap: () async {
        if (await controller.canGoBack()) {
          /// 返回H5的上一页
          controller.goBack();
        } else {
          /// 返回flutter的上一页
          if (context.mounted) NavigatorUtil.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        child: Icon(
          Icons.arrow_back,
          color: backButtonColor,
          size: 26,
        ),
      ),
    );
  }

  /// 标题
  Widget _title(Color backButtonColor) {
    return Center(
      child: Text(
        widget.title ?? '',
        style: TextStyle(color: backButtonColor, fontSize: 20),
      ),
    );
  }
}
