import 'dart:io';
import 'dart:convert';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/components/loading_widget.dart';
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
  bool _isLoading = true; // 加载状态

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

      // 给初始 URL 添加 token 参数
      url = _addTokenToUrl(url!);
    }
    _initWebViewController();
  }

  /// 给 URL 添加 token 参数
  String _addTokenToUrl(String urlString) {
    try {
      Uri uri = Uri.parse(urlString);
      String? token = LoginDao.getToken();

      // 如果已经有 token 参数，就不添加
      if (uri.queryParameters.containsKey('token') || token == null) {
        return urlString;
      }

      // 添加 token 参数
      Map<String, String> queryParams = Map.from(uri.queryParameters);
      queryParams['token'] = token;

      Uri newUri = uri.replace(queryParameters: queryParams);
      return newUri.toString();
    } catch (e) {
      debugPrint('❌ 添加 token 参数失败: $e');
      return urlString;
    }
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
            print('页面加载开始: $url');

            /// 页面加载开始
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            _injectUserInfo();
          },
          onPageFinished: (String url) {
            /// 页面加载完成
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _handleBackForbid();
            _injectUserInfo();
          },
          onWebResourceError: (WebResourceError error) {
            /// 页面加载错误
            print('WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            // 检查是否需要拦截并返回主页
            if (_isToMain(request.url)) {
              /// 拦截URL，返回flutter页面
              NavigatorUtil.pop(context);
              return NavigationDecision.prevent;
            }

            // 检查 URL 是否已经有 token 参数
            String requestUrl = request.url;
            String? token = LoginDao.getToken();

            if (token != null) {
              try {
                Uri uri = Uri.parse(requestUrl);
                // 如果没有 token 参数，添加 token 并重新加载
                if (!uri.queryParameters.containsKey('token')) {
                  String newUrl = _addTokenToUrl(requestUrl);
                  // 阻止原请求，加载带 token 的新 URL
                  controller.loadRequest(Uri.parse(newUrl));
                  return NavigationDecision.prevent;
                }
              } catch (e) {
                debugPrint('❌ 处理导航请求失败: $e');
              }
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

  /// 将用户登录信息注入到浏览器的 localStorage
  void _injectUserInfo() async {
    // 获取用户信息，如果没有则使用空对象
    Map<String, dynamic> userInfo = LoginDao.getLocalUserInfo() ?? {};

    // 注入用户信息到 localStorage
    String userInfoJson = jsonEncode(userInfo);
    // 将 JSON 字符串作为字符串值存储，需要转义单引号和反斜杠
    String escapedJson =
        userInfoJson.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

    debugPrint('✅ 用户信息已成功注入到 WebView localStorage: $escapedJson');

    String jsCode = "localStorage.setItem('userInfo', '$escapedJson');";
    await controller.runJavaScript(jsCode);
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
            Expanded(
              child: LoadingWidget(
                isLoading: _isLoading,
                cover: true, // 使用覆盖模式，加载动画覆盖在 WebView 上
                child: WebViewWidget(controller: controller),
              ),
            ),
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
