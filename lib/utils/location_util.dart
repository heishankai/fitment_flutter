import 'dart:convert';
import 'package:flutter_hi_cache/flutter_hi_cache.dart';

/// 位置信息工具类
class LocationUtil {
  // 本地存储的 key
  static const String _locationStorageKey = 'user_location_info';

  /// 保存位置信息到本地存储
  /// [location] 位置信息（包含地址、省市区等）
  /// [currentLocation] 当前位置（包含经纬度）
  static void saveLocationToLocal(
    Map<String, dynamic> location,
    Map<String, dynamic> currentLocation,
  ) {
    try {
      final locationData = {
        'location': location,
        'currentLocation': currentLocation,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      HiCache.getInstance().setString(
        _locationStorageKey,
        jsonEncode(locationData),
      );
      print('✅ 位置信息保存成功');
    } catch (e) {
      print('❌ 保存位置信息失败: $e');
    }
  }

  /// 从本地存储读取位置信息
  /// 返回包含 location 和 currentLocation 的 Map，如果不存在则返回 null
  static Map<String, dynamic>? loadLocationFromLocal() {
    try {
      final saved = HiCache.getInstance().get(_locationStorageKey);
      if (saved != null && saved is String) {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        return {
          'location': data['location'],
          'currentLocation': data['currentLocation'],
        };
      }
    } catch (e) {
      print('❌ 读取位置信息失败: $e');
    }
    return null;
  }

  /// 清除位置信息
  static void clearLocation() {
    try {
      HiCache.getInstance().remove(_locationStorageKey);
      print('✅ 位置信息已清除');
    } catch (e) {
      print('❌ 清除位置信息失败: $e');
    }
  }
}
