import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/config/h5_config.dart';
import 'package:fitment_flutter/pages/webview.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';
import 'package:fitment_flutter/utils/new_order_notification.dart';

/// 首页：使用 H5 /fitment-h5/home 页面
class HomeH5Page extends StatefulWidget {
  const HomeH5Page({super.key});

  @override
  State<HomeH5Page> createState() => _HomeH5PageState();
}

class _HomeH5PageState extends State<HomeH5Page>
    with AutomaticKeepAliveClientMixin, TabPageRefreshMixin<HomeH5Page> {
  static const String _homePath = '/fitment-h5/home';
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    NewOrderNotification.ensureInitialized();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void onTabSelected() {
    // 切换 Tab 不刷新，仅从 WebView 返回时刷新
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        top: true,
        child: HiWebView(
          key: ValueKey(_refreshKey),
          url: H5Config.getH5Url(_homePath),
          hideAppBar: true,
          statusBarColor: '2d635e',
          onOpenWebViewReturn: () {
            // 从地图选择器/订单详情等 WebView 返回时刷新
            if (mounted) setState(() => _refreshKey++);
          },
        ),
      ),
    );
  }
}
