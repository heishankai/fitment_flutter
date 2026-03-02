import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

/// 新订单提醒工具：参考 fitment-h5 实现震动 + 本地通知
///
/// 注意：仅在 App 前台时生效。App 在后台时 Socket 被系统暂停，
/// 收不到 new-order 事件，因此不会触发。如需后台通知，需接入 FCM/APNs 服务端推送。
class NewOrderNotification {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// 初始化通知（在首页 initState 时调用）
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }
      }
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {},
      );
      _initialized = true;
    } catch (e) {
      // 忽略初始化失败，不影响主流程
    }
  }

  /// 新订单来了：震动 + 本地通知（参考 fitment-h5）
  static Future<void> onNewOrder(Map<String, dynamic> order) async {
    await ensureInitialized();

    // 1. 震动提醒
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 500);
      }
    } catch (_) {}

    // 2. 本地通知（后台或切到其他 tab 时用户能看到）
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) return;
      }
      final workKind = order['work_kind_name']?.toString().trim() ?? '新订单';
      const androidDetails = AndroidNotificationDetails(
        'fitment_new_order',
        '新订单提醒',
        channelDescription: '师傅端新订单推送',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        '新订单来了',
        '您有一个新的$workKind订单，请及时查看',
        details,
        payload: order['id']?.toString(),
      );
    } catch (_) {}
  }
}
