import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_hi_cache/flutter_hi_cache.dart';
import 'package:fitment_flutter/dao/order_dao.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/dao/user_dao.dart';
import 'package:fitment_flutter/pages/home/header_content.dart';
import 'package:fitment_flutter/pages/home/order_popup.dart';
import 'package:fitment_flutter/pages/home/order_detail.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/config/h5_config.dart';
import 'package:fitment_flutter/pages/webview.dart';
import 'package:fitment_flutter/utils/new_order_notification.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/mixins/tab_page_refresh_mixin.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TabPageRefreshMixin<HomePage>, WidgetsBindingObserver {
  IO.Socket? _socket;
  List<Map<String, dynamic>> _orders = [];
  int _newOrderCount = 0;
  bool _isRefreshing = false;
  Map<String, dynamic>? _location; // 仅含省市区等展示用地址

  // 订单弹窗相关
  bool _showOrderPopup = false;
  Map<String, dynamic>? _currentOrder;
  double _currentOrderDistance = 0.0;
  int? _acceptingOrderId;

  @override
  bool get wantKeepAlive => true;

  @override
  void onTabSelected() {
    _onRefresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 从 /craftsman-user 接口获取位置信息，不依赖本地存储
    _loadUserInfo();
    _loadOrders();
    _connectSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectSocket();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 从后台切回前台时，重新连接 Socket（后台时系统会暂停网络连接）
    if (state == AppLifecycleState.resumed && mounted) {
      _disconnectSocket();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _connectSocket();
      });
    }
  }

  /// 从 /craftsman-user 接口获取用户信息并提取位置信息
  Future<void> _loadUserInfo() async {
    try {
      print('👤 开始获取用户信息');
      final result = await UserDao.getUserInfo();

      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'] as Map<String, dynamic>;

        // 保存用户信息到本地缓存
        final userInfoJson = jsonEncode(userData);
        HiCache.getInstance().setString(LoginDao.userInfo, userInfoJson);
        print('✅ 用户信息已保存到本地缓存');

        // 从 API 提取省市区用于展示（不需要经纬度）
        final province = userData['province'];
        final city = userData['city'];
        final district = userData['district'];
        final address = userData['address'];

        print(
            '📍 从API获取省市区: province=$province, city=$city, district=$district');

        final provinceStr = (province?.toString() ?? '').trim();
        final cityStr = (city?.toString() ?? '').trim();
        final districtStr = (district?.toString() ?? '').trim();
        final addressStr = (address?.toString() ?? '').trim();

        // 构建展示地址：优先 address，否则拼接省市区
        String displayAddress = addressStr;
        if (displayAddress.isEmpty &&
            (provinceStr.isNotEmpty ||
                cityStr.isNotEmpty ||
                districtStr.isNotEmpty)) {
          displayAddress = '$provinceStr$cityStr$districtStr';
        }

        if (mounted) {
          setState(() {
            _location = displayAddress.isNotEmpty
                ? {
                    'address': displayAddress,
                    'province': provinceStr,
                    'city': cityStr,
                    'district': districtStr,
                    'formatted_address': displayAddress,
                  }
                : null;
          });
          print('📍 位置信息已更新: $displayAddress');
        }
      }
    } catch (e) {
      print('❌ 获取用户信息失败: $e');
    }
  }

  /// 加载订单列表
  Future<void> _loadOrders() async {
    try {
      final result = await OrderDao.getCraftsmanOrders();
      if (result['success'] == true && result['data'] != null) {
        final orderList = result['data'] as List;
        setState(() {
          _orders = orderList
              .where((order) => order['order_status'] != 4)
              .cast<Map<String, dynamic>>()
              .toList();
        });
      }
    } catch (e) {
      print('❌ 加载订单列表失败: $e');
    }
  }

  /// 连接 WebSocket
  void _connectSocket() {
    final token = LoginDao.getToken();
    if (token == null || token.isEmpty) {
      print('⚠️ 未登录，无法连接 WebSocket');
      return;
    }

    try {
      // 构建 WebSocket URL
      String wsUrl;
      if (const bool.fromEnvironment('dart.vm.product')) {
        // 生产环境
        wsUrl = 'https://zjiangyun.cn';
      } else {
        // 开发环境
        wsUrl = Platform.isAndroid
            ? 'http://10.0.2.2:3000'
            : 'http://localhost:3000';
      }

      _socket = IO.io(
        '$wsUrl/order',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .build(),
      );

      _socket!.onConnect((_) {
        print('✅ 订单WebSocket已连接');
      });

      _socket!.onConnectError((error) {
        print('❌ WebSocket连接失败: $error');
      });

      _socket!.onDisconnect((reason) {
        print('⚠️ WebSocket断开连接: $reason');
      });

      // 监听新订单弹窗
      _socket!.on('new-order-popup', (data) {
        print('收到新订单弹窗: $data');
        final order = data['order'] as Map<String, dynamic>?;
        final distance = (data['distance'] as num?)?.toDouble() ?? 0.0;

        if (order != null) {
          // 检查订单是否已存在
          final existingIndex =
              _orders.indexWhere((o) => o['id'] == order['id']);
          if (existingIndex == -1 && order['order_status'] == 1) {
            // 参考 fitment-h5：震动 + 本地通知
            NewOrderNotification.onNewOrder(order);
            setState(() {
              _orders.insert(0, order);
              _newOrderCount++;
              _currentOrder = order;
              _currentOrderDistance = distance;
              _showOrderPopup = true;
            });
          }
        }
      });

      // 监听新订单（列表显示）
      _socket!.on('new-order', (data) {
        print('收到新订单: $data');
        final order = data['order'] as Map<String, dynamic>?;

        if (order != null) {
          final existingIndex =
              _orders.indexWhere((o) => o['id'] == order['id']);
          if (existingIndex == -1 && order['order_status'] == 1) {
            // 参考 fitment-h5：震动 + 本地通知
            NewOrderNotification.onNewOrder(order);
            setState(() {
              _orders.insert(0, order);
              _newOrderCount++;
            });
          }
        }
      });

      // 监听订单状态更新
      _socket!.on('order-status-updated', (data) {
        print('订单状态更新: $data');
        final order = data['order'] as Map<String, dynamic>?;
        if (order != null) {
          final index = _orders.indexWhere((o) => o['id'] == order['id']);
          if (index != -1) {
            setState(() {
              _orders[index] = {..._orders[index], ...order};
            });
          }
        }
      });

      // 监听接单成功
      _socket!.on('order-accepted', (data) {
        print('接单成功: $data');
        final order = data['order'] as Map<String, dynamic>?;
        if (order != null) {
          final index = _orders.indexWhere((o) => o['id'] == order['id']);
          if (index != -1) {
            setState(() {
              _orders[index] = {..._orders[index], ...order};
            });
          }
        }
        _loadOrders();
      });

      // 监听订单已被接单
      _socket!.on('order-taken', (data) {
        print('订单已被接单: $data');
        final orderId = data['orderId'] as int?;
        if (orderId != null) {
          final index = _orders.indexWhere((o) => o['id'] == orderId);
          if (index != -1) {
            setState(() {
              _orders[index]['order_status'] = 2;
              _orders[index]['order_status_name'] = '已接单';
            });
          }

          // 如果当前弹窗的订单被接单，关闭弹窗
          if (_currentOrder != null && _currentOrder!['id'] == orderId) {
            setState(() {
              _showOrderPopup = false;
              _currentOrder = null;
            });
          }
        }
      });

      // 监听错误
      _socket!.on('error', (data) {
        print('WebSocket错误: $data');
        final message = data['message'] as String?;
        if (message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
    } catch (e) {
      print('❌ 连接WebSocket失败: $e');
    }
  }

  /// 断开 WebSocket
  void _disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// 接单
  Future<void> _handleAcceptOrder(int orderId) async {
    final order = _orders.firstWhere((o) => o['id'] == orderId);
    if (order['order_status'] != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('订单状态不正确，无法接单')),
      );
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认接单'),
        content: Text('确定要接这个${order['work_kind_name']}订单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _acceptingOrderId = orderId;
    });

    try {
      if (_socket != null && _socket!.connected) {
        // 使用 WebSocket 发送接单请求
        _socket!.emit('accept-order', {'orderId': orderId});

        // 等待接单结果（通过监听事件）
        // 这里简化处理，实际应该使用 Completer 等待结果
        await Future.delayed(const Duration(seconds: 2));
      } else {
        // 使用 HTTP 接口
        final result = await OrderDao.acceptOrder(orderId);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('接单成功')),
          );
          _loadOrders();

          // 跳转到我的施工页面
          NavigatorUtil.jumpH5(
            context: context,
            url: H5Config.getH5Url('/fitment-h5/mine/my-construction'),
            title: '我的工地订单',
            statusBarColor: '2d635e',
          );
        } else {
          throw Exception(result['message'] ?? '接单失败');
        }
      }

      // 关闭弹窗
      setState(() {
        _showOrderPopup = false;
        _currentOrder = null;
      });
    } catch (e) {
      print('❌ 接单失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('接单失败: $e')),
        );
      }
    } finally {
      setState(() {
        _acceptingOrderId = null;
      });
    }
  }

  /// 点击位置区域，跳转 H5 地图选择页；返回后刷新位置信息
  void _openMapPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiWebView(
          url: H5Config.getH5Url('/fitment-h5/home/map-picker'),
          title: '选择位置',
          statusBarColor: '2d635e',
        ),
      ),
    ).then((_) => _loadUserInfo()); // H5 选择完成后会更新 API，返回后刷新
  }

  /// 清除新订单计数
  void _clearNewOrderCount() {
    setState(() {
      _newOrderCount = 0;
    });
  }

  /// 下拉刷新：获取最新用户信息（含位置）、订单列表
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    try {
      print('🔄 开始下拉刷新');
      // 从 /craftsman-user 重新获取用户信息（含 latitude、longitude、省市区等位置信息）
      await _loadUserInfo();
      // 重新加载订单列表
      await _loadOrders();
      print('✅ 下拉刷新完成');
    } catch (e) {
      print('❌ 刷新失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// 格式化时间
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);

      if (diff.inDays == 0) {
        return DateFormat('HH:mm').format(time);
      } else if (diff.inDays == 1) {
        return '昨天 ${DateFormat('HH:mm').format(time)}';
      } else {
        return DateFormat('MM-dd HH:mm').format(time);
      }
    } catch (_) {
      return '';
    }
  }

  /// 获取订单状态类型（参考 uni.scss 行为色）
  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning; // 待接单
      case 2:
        return AppColors.primary; // 已接单
      case 3:
        return AppColors.success; // 已完成
      case 4:
        return AppColors.error; // 已取消
      default:
        return AppColors.textGrey;
    }
  }

  /// 跳转到订单详情
  void _goToOrderDetail(int orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: orderId),
      ),
    ).then((_) {
      // 返回后刷新订单列表
      _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 头部
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: HeaderContent(
                  newOrderCount: _newOrderCount,
                  location: _location,
                  onClearNewOrderCount: _clearNewOrderCount,
                  onOpenMapPicker: _openMapPicker,
                ),
              ),

              // 订单列表
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: AppColors.textPlaceholder,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无订单，等待新订单...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final isNewOrder = order['order_status'] == 1;
                            final isAccepting =
                                _acceptingOrderId == order['id'];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isNewOrder
                                      ? AppColors.warning.withOpacity(0.3)
                                      : AppColors.border,
                                  width: isNewOrder ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _goToOrderDetail(order['id']),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 订单头部
                                        Row(
                                          children: [
                                            Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      AppColors.primary,
                                                      AppColors.primaryGradientEnd,
                                                    ],
                                                  ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.work_outline,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          order['work_kind_name'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getStatusColor(
                                                            order['order_status'] ??
                                                                0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Text(
                                                          order['order_status_name'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (order['createdAt'] !=
                                                      null)
                                                    Text(
                                                      _formatTime(
                                                          order['createdAt']),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .textGrey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // 订单信息
                                        _buildInfoRow(
                                          Icons.location_on_outlined,
                                          order['location'] ??
                                              '${order['province']} ${order['city']} ${order['district']}',
                                        ),
                                        _buildInfoRow(
                                          Icons.home_outlined,
                                          '${order['houseType'] == 'new' ? '新房' : '老房'} · ${order['roomType']} · ${order['area']}m²',
                                        ),
                                        if (order['wechat_user'] != null)
                                          _buildInfoRow(
                                            Icons.person_outline,
                                            order['wechat_user']['nickname'] ??
                                                '用户',
                                          ),

                                        // 操作按钮
                                        if (isNewOrder) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed: isAccepting
                                                  ? null
                                                  : () => _handleAcceptOrder(
                                                      order['id']),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: isAccepting
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                Color>(
                                                          Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : const Text(
                                                      '立即接单',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),

          // 订单弹窗
          OrderPopup(
            show: _showOrderPopup,
            order: _currentOrder,
            distance: _currentOrderDistance,
            onGrabOrder: _handleAcceptOrder,
            onClose: () {
              setState(() {
                _showOrderPopup = false;
                _currentOrder = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
