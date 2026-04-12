import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import 'package:fitment_flutter/components/media_picker.dart';
import 'package:fitment_flutter/config/api_config.dart';
import 'package:fitment_flutter/config/h5_config.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/utils/new_order_notification.dart';

class HiWebView extends StatefulWidget {
  final String url;
  final String? title;
  final String? statusBarColor;
  final bool hideAppBar;
  final bool backForbid;

  /// 从 openWebView 打开的子页面返回时回调（用于首页从地图/订单详情返回后刷新）
  final VoidCallback? onOpenWebViewReturn;

  const HiWebView({
    super.key,
    required this.url,
    this.title,
    this.statusBarColor,
    this.hideAppBar = false,
    this.backForbid = false,
    this.onOpenWebViewReturn,
  });

  @override
  State<HiWebView> createState() => _HiWebViewState();
}

class _HiWebViewState extends State<HiWebView> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _isUploading = false;
  String _webTitle = '';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  final List<String> _catchUrls = [
    'https://www.baidu.com',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestNotificationPermission();
        _initializeNotifications();
      }
    });
  }

  // -------------------------
  // URL 处理
  // -------------------------
  String _prepareUrl(String url) {
    var result = url;

    if (Platform.isAndroid && result.contains('localhost')) {
      result = result.replaceAll('localhost', '10.0.2.2');
    }

    if (!result.contains('token=')) {
      final token = LoginDao.getToken();
      if (token != null) {
        final uri = Uri.parse(result);
        result = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'token': token,
        }).toString();
      }
    }

    return result;
  }

  // -------------------------
  // JS 注入
  // -------------------------
  String _injectWxJs() {
    return '''
      (function () {
        if (window.fitment_flutter) return;

        window.fitment_flutter = {
          chooseImage: function (options) {
            options = options || {};
            return window.flutter_inappwebview
              .callHandler('chooseMedia', {
                count: options.count || 1,
                allowVideo: false,
                upload: options.upload || null
              })
              .then(function (res) {
                if (!res) {
                  return {
                    tempFilePaths: [],
                    tempFiles: []
                  };
                }
                
                // 如果上传成功，返回包含 URL 的结果
                if (res[0] && res[0].url) {
                  return {
                    tempFilePaths: res.map(i => i.path || i.url),
                    tempFiles: res.map(i => ({
                      path: i.path || i.url,
                      url: i.url,
                      type: i.type || 'image',
                      size: i.size || 0
                    }))
                  };
                }
                
                // 如果没有上传，返回原始路径
                return {
                  tempFilePaths: res.map(i => i.path),
                  tempFiles: res
                };
              });
          },

          chooseMedia: function (options) {
            options = options || {};
            return window.flutter_inappwebview
              .callHandler('chooseMedia', {
                count: options.count || 1,
                allowVideo: options.allowVideo || false,
                upload: options.upload || null
              })
              .then(function (res) {
                if (!res) {
                  return [];
                }
                
                // 如果上传成功，返回包含 URL 的结果
                if (res[0] && res[0].url) {
                  return res.map(i => ({
                    path: i.path || i.url,
                    url: i.url,
                    type: i.type || 'image',
                    size: i.size || 0
                  }));
                }
                
                // 如果没有上传，返回原始路径
                return res;
              });
          },

          uploadImage: function (filePath, options) {
            options = options || {};
            return window.flutter_inappwebview
              .callHandler('uploadImage', {
                filePath: filePath,
                fieldName: options.fieldName || 'file',
                extraFields: options.extraFields || {}
              });
          },

          /** 打开新 WebView 页面，用于 map-picker、order 等需独立页面的路由 */
          openWebView: function (path, title) {
            if (!path || typeof path !== 'string') return;
            return window.flutter_inappwebview
              .callHandler('openWebView', { path: path, title: title || '' });
          },

          /** 新订单来了：震动 + 本地通知，H5 收到新订单时调用 */
          onNewOrder: function (order) {
            if (!order) return;
            var data = typeof order === 'string' ? (function(){try{return JSON.parse(order);}catch(e){return null;}})() : order;
            if (!data) return;
            return window.flutter_inappwebview
              .callHandler('FlutterOnNewOrder', data);
          },

          /** 关闭当前 Flutter WebView（等价 Navigator.pop，不处理 H5 内 history） */
          pop: function () {
            return window.flutter_inappwebview.callHandler('nativePop');
          }
        };

        console.log('[Hybrid wx bridge ready]');
      })();
    ''';
  }

  // -------------------------
  // 是否拦截返回
  // -------------------------
  bool _shouldExit(String url) {
    return _catchUrls.any((u) => url.startsWith(u));
  }

  /// 与系统返回 / 导航栏返回一致：Web 有历史则后退，否则关闭当前 WebView
  Future<void> _handleHybridBack() async {
    if (!mounted) return;
    if (_controller != null && await _controller!.canGoBack()) {
      if (!mounted) return;
      await _controller!.goBack();
    } else {
      if (!mounted) return;
      NavigatorUtil.pop(context);
    }
  }

  // -------------------------
  // 通知与震动（供 H5 调用）
  // -------------------------

  /// 请求通知权限
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('❌ 请求通知权限失败: $e');
      }
    }
  }

  /// 初始化通知插件
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('🔔 通知被点击: ${details.payload}');
        },
      );
      _notificationsInitialized = true;
      debugPrint('✅ 通知插件初始化成功');
    } catch (e) {
      debugPrint('❌ 初始化通知插件失败: $e');
    }
  }

  /// 显示通知
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          debugPrint('⚠️ 通知权限未授予');
          return;
        }
      }
      if (!_notificationsInitialized) {
        await _initializeNotifications();
      }
      const androidDetails = AndroidNotificationDetails(
        'fitment_channel',
        '智惠装通知',
        channelDescription: '智惠装应用通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const details = NotificationDetails(android: androidDetails);
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('✅ 通知已显示: $title - $body');
    } catch (e) {
      debugPrint('❌ 显示通知失败: $e');
    }
  }

  /// 处理 H5 通知请求
  Future<void> _handleShowNotification(dynamic args) async {
    try {
      Map<String, dynamic>? params;
      if (args is List && args.isNotEmpty) {
        if (args[0] is String) {
          params = jsonDecode(args[0]) as Map<String, dynamic>?;
        } else if (args[0] is Map) {
          params = args[0] as Map<String, dynamic>;
        }
      }
      if (params == null) {
        debugPrint('⚠️ 通知参数格式错误');
        return;
      }
      await _showNotification(
        title: params['title'] ?? '通知',
        body: params['body'] ?? '',
        payload: params['payload'],
      );
    } catch (e) {
      debugPrint('❌ 处理通知请求失败: $e');
    }
  }

  /// 处理 H5 震动请求
  Future<void> _handleVibrate(dynamic args) async {
    try {
      int duration = 500;
      if (args is List && args.isNotEmpty) {
        if (args[0] is num) {
          duration = args[0].toInt();
        } else if (args[0] is String) {
          duration = int.tryParse(args[0]) ?? 500;
        } else if (args[0] is Map) {
          final params = args[0] as Map<String, dynamic>;
          if (params['duration'] != null) {
            duration = (params['duration'] as num).toInt();
          }
        }
      }
      duration = duration.clamp(10, 5000);
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: duration);
        debugPrint('✅ 震动成功，时长: ${duration}ms');
      } else {
        debugPrint('⚠️ 设备不支持震动');
      }
    } catch (e) {
      debugPrint('❌ 震动失败: $e');
    }
  }

  /// 注入通知和震动 JS Bridge
  String _injectNotificationVibrateJs() {
    return '''
      (function() {
        // 提供通知方法
        // 用法: window.FlutterShowNotification({ title: '标题', body: '内容', payload: '可选' })
        if (!window.FlutterShowNotification) {
          window.FlutterShowNotification = function(params) {
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              if (typeof params === 'string') {
                try { params = JSON.parse(params); } catch (e) { return; }
              }
              window.flutter_inappwebview.callHandler('FlutterShowNotification', params);
            }
          };
        }
        // 提供震动方法
        // 用法: window.FlutterVibrate(500) 或 window.FlutterVibrate({ duration: 500 })
        if (!window.FlutterVibrate) {
          window.FlutterVibrate = function(duration) {
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              if (typeof duration === 'number') {
                window.flutter_inappwebview.callHandler('FlutterVibrate', duration);
              } else if (typeof duration === 'object' && duration !== null) {
                window.flutter_inappwebview.callHandler('FlutterVibrate', duration);
              } else {
                window.flutter_inappwebview.callHandler('FlutterVibrate', 500);
              }
            }
          };
        }
        console.log('[Hybrid] FlutterShowNotification、FlutterVibrate 已注入');
      })();
    ''';
  }

  // -------------------------
  // Build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final statusColor = Color(
      int.parse('0xff${widget.statusBarColor ?? 'ffffff'}'),
    );
    final iconColor =
        widget.statusBarColor == 'ffffff' ? Colors.black : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _handleHybridBack();
      },
      child: Scaffold(
        body: Column(
          children: [
            if (!widget.hideAppBar) _buildAppBar(statusColor, iconColor),
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(_prepareUrl(widget.url)),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsBackForwardNavigationGestures: true,
                    ),
                    // 使用 initialUserScripts 在文档加载时注入，确保真机/生产环境下 bridge 可用
                    // 解决 onLoadStop 在部分真机/导航场景下注入时机不可靠的问题
                    initialUserScripts: UnmodifiableListView<UserScript>([
                      UserScript(
                        source: _injectWxJs(),
                        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                      ),
                      UserScript(
                        source: _injectNotificationVibrateJs(),
                        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                      ),
                    ]),

                    // -------------------------
                    // WebView Created
                    // -------------------------
                    onWebViewCreated: (controller) {
                      _controller = controller;

                      /// ⭐ JS Bridge：chooseMedia（支持自动上传）
                      controller.addJavaScriptHandler(
                        handlerName: 'chooseMedia',
                        callback: (args) async {
                          try {
                            final params =
                                args.isNotEmpty ? args[0] as Map : {};
                            final uploadConfig =
                                params['upload'] as Map<String, dynamic>?;

                            // 选择媒体文件
                            // 如果 allowVideo 为 true 且有上传配置，只显示视频选项
                            final allowVideo = params['allowVideo'] ?? false;
                            final videoOnly =
                                allowVideo && uploadConfig != null;

                            final result = await MediaPicker.showPicker(
                              context: context,
                              maxCount: params['count'] ?? 1,
                              allowVideo: allowVideo,
                              videoOnly: videoOnly,
                            );

                            if (result == null || result.isEmpty) {
                              return null;
                            }

                            // 如果没有上传配置，直接返回文件信息
                            if (uploadConfig == null) {
                              return result.map((media) {
                                return {
                                  'path': media.file.path,
                                  'type': media.type == MediaType.image
                                      ? 'image'
                                      : 'video',
                                  'size': media.file.lengthSync(),
                                };
                              }).toList();
                            }

                            // 如果有上传配置，自动上传
                            final uploadUrl = uploadConfig['url'] as String?;
                            if (uploadUrl == null || uploadUrl.isEmpty) {
                              // 如果没有上传 URL，返回文件信息
                              return result.map((media) {
                                return {
                                  'path': media.file.path,
                                  'type': media.type == MediaType.image
                                      ? 'image'
                                      : 'video',
                                  'size': media.file.lengthSync(),
                                };
                              }).toList();
                            }

                            // 处理上传 URL：如果是相对路径，使用 ApiConfig 构建完整 URL
                            String finalUploadUrl = uploadUrl;
                            if (uploadUrl.startsWith('/')) {
                              // 相对路径，使用 ApiConfig 构建完整 URL
                              finalUploadUrl =
                                  ApiConfig.createUri(uploadUrl).toString();
                            } else if (!uploadUrl.startsWith('http://') &&
                                !uploadUrl.startsWith('https://')) {
                              // 既不是相对路径也不是完整 URL，当作相对路径处理
                              finalUploadUrl =
                                  ApiConfig.createUri('/$uploadUrl').toString();
                            }

                            // 准备上传参数
                            final fieldName =
                                uploadConfig['name'] as String? ?? 'file';
                            final headers = uploadConfig['headers']
                                as Map<String, dynamic>?;
                            final formData = uploadConfig['formData']
                                as Map<String, dynamic>?;

                            // 转换 headers
                            final headersMap = <String, String>{};
                            if (headers != null) {
                              headers.forEach((key, value) {
                                headersMap[key] = value.toString();
                              });
                            }

                            // 转换 formData
                            final formDataMap = <String, String>{};
                            if (formData != null) {
                              formData.forEach((key, value) {
                                formDataMap[key] = value.toString();
                              });
                            }

                            // 上传每个文件（显示上传 loading）
                            if (mounted) setState(() => _isUploading = true);
                            final List<Map<String, dynamic>> uploadResults = [];
                            try {
                              for (final media in result) {
                              try {
                                final uploadResultsList =
                                    await MediaPicker.upload(
                                  mediaFiles: [media],
                                  uploadUrl: finalUploadUrl,
                                  fieldName: fieldName,
                                  headers:
                                      headersMap.isNotEmpty ? headersMap : null,
                                  extraFields: formDataMap.isNotEmpty
                                      ? formDataMap
                                      : null,
                                );

                                if (uploadResultsList.isNotEmpty) {
                                  final uploadResult = uploadResultsList.first;
                                  // 使用工具函数提取 URL
                                  final url =
                                      MediaPicker.extractUrlFromUploadResult(
                                          uploadResult);

                                  if (url != null) {
                                    uploadResults.add({
                                      'path': media.file.path,
                                      'url': url,
                                      'type': media.type == MediaType.image
                                          ? 'image'
                                          : 'video',
                                      'size': media.file.lengthSync(),
                                    });
                                  } else {
                                    // 上传失败，返回错误信息
                                    uploadResults.add({
                                      'path': media.file.path,
                                      'type': media.type == MediaType.image
                                          ? 'image'
                                          : 'video',
                                      'size': media.file.lengthSync(),
                                      'error':
                                          uploadResult['message'] ?? '上传失败',
                                    });
                                  }
                                } else {
                                  // 上传失败
                                  uploadResults.add({
                                    'path': media.file.path,
                                    'type': media.type == MediaType.image
                                        ? 'image'
                                        : 'video',
                                    'size': media.file.lengthSync(),
                                    'error': '上传失败：无返回结果',
                                  });
                                }
                              } catch (e) {
                                // 上传异常
                                uploadResults.add({
                                  'path': media.file.path,
                                  'type': media.type == MediaType.image
                                      ? 'image'
                                      : 'video',
                                  'size': media.file.lengthSync(),
                                  'error': '上传失败: $e',
                                });
                              }
                            }
                            } finally {
                              if (mounted) setState(() => _isUploading = false);
                            }

                            return uploadResults;
                          } catch (e) {
                            debugPrint('选择媒体失败: $e');
                            return null;
                          }
                        },
                      );

                      /// ⭐ JS Bridge：通知
                      controller.addJavaScriptHandler(
                        handlerName: 'FlutterShowNotification',
                        callback: (args) async {
                          await _handleShowNotification(args);
                        },
                      );

                      /// ⭐ JS Bridge：震动
                      controller.addJavaScriptHandler(
                        handlerName: 'FlutterVibrate',
                        callback: (args) async {
                          await _handleVibrate(args);
                        },
                      );

                      /// ⭐ JS Bridge：关闭当前原生 WebView（window.fitment_flutter.pop）
                      /// 注意：嵌在 Tab 内的首页 WebView 没有可 pop 的 Flutter 路由，
                      /// 若走 NavigatorUtil.pop → SystemNavigator.pop 会直接退出 App（安卓上像「失败」）；
                      /// H5 await pop() 也可能因 Activity 结束导致 Promise reject，进而误判「接口失败」。
                      controller.addJavaScriptHandler(
                        handlerName: 'nativePop',
                        callback: (args) async {
                          if (!mounted) return true;
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else if (_controller != null &&
                              await _controller!.canGoBack()) {
                            await _controller!.goBack();
                          }
                          return true;
                        },
                      );

                      /// ⭐ JS Bridge：打开新 WebView（map-picker、order 等）
                      controller.addJavaScriptHandler(
                        handlerName: 'openWebView',
                        callback: (args) async {
                          if (!mounted) return;
                          try {
                            final params =
                                args.isNotEmpty ? args[0] as Map : {};
                            String path =
                                (params['path'] as String?)?.trim() ?? '';
                            final title = params['title'] as String?;
                            if (path.isEmpty) return;
                            if (path.startsWith('/') &&
                                !path.startsWith('/fitment-h5')) {
                              path = '/fitment-h5$path';
                            }
                            final url = H5Config.getH5Url(path);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => HiWebView(
                                  url: url,
                                  title: title,
                                  statusBarColor: '2d635e',
                                ),
                              ),
                            );
                            // 从子 WebView 返回后触发刷新
                            widget.onOpenWebViewReturn?.call();
                          } catch (e) {
                            debugPrint('openWebView 失败: $e');
                          }
                        },
                      );

                      /// ⭐ JS Bridge：新订单来了（震动 + 通知）
                      controller.addJavaScriptHandler(
                        handlerName: 'FlutterOnNewOrder',
                        callback: (args) async {
                          try {
                            final order = args.isNotEmpty
                                ? args[0] as Map<String, dynamic>?
                                : null;
                            if (order != null) {
                              await NewOrderNotification.onNewOrder(order);
                            }
                          } catch (e) {
                            debugPrint('FlutterOnNewOrder 失败: $e');
                          }
                        },
                      );

                      /// ⭐ JS Bridge：uploadImage
                      controller.addJavaScriptHandler(
                        handlerName: 'uploadImage',
                        callback: (args) async {
                          try {
                            final params =
                                args.isNotEmpty ? args[0] as Map : {};
                            final filePath = params['filePath'] as String?;
                            final fieldName =
                                params['fieldName'] as String? ?? 'file';
                            final extraFields =
                                params['extraFields'] as Map<String, String>?;

                            if (filePath == null || filePath.isEmpty) {
                              return {
                                'success': false,
                                'message': '文件路径不能为空',
                                'code': 400,
                              };
                            }

                            // 创建 MediaFile 对象
                            final file = File(filePath);
                            if (!await file.exists()) {
                              return {
                                'success': false,
                                'message': '文件不存在',
                                'code': 404,
                              };
                            }

                            // 判断文件类型
                            final extension =
                                filePath.split('.').last.toLowerCase();
                            final isImage = [
                              'jpg',
                              'jpeg',
                              'png',
                              'gif',
                              'webp'
                            ].contains(extension);
                            final mediaFile = MediaFile(
                              file: file,
                              type: isImage ? MediaType.image : MediaType.video,
                            );

                            // 获取上传 URL
                            final uploadUrl =
                                ApiConfig.createUri('/upload').toString();

                            // 获取 token 用于请求头
                            final token = LoginDao.getToken();
                            final headers = <String, String>{
                              'Accept': 'application/json',
                            };
                            if (token != null && token.isNotEmpty) {
                              headers['Authorization'] = 'Bearer $token';
                            }

                            // 转换 extraFields
                            final extraFieldsMap = <String, String>{};
                            if (extraFields != null) {
                              extraFields.forEach((key, value) {
                                extraFieldsMap[key] = value.toString();
                              });
                            }

                            // 显示上传 loading
                            if (mounted) setState(() => _isUploading = true);
                            try {
                              // 使用 MediaPicker.upload 上传
                              final results = await MediaPicker.upload(
                                mediaFiles: [mediaFile],
                                uploadUrl: uploadUrl,
                                fieldName: fieldName,
                                headers: headers,
                                extraFields: extraFieldsMap.isNotEmpty
                                    ? extraFieldsMap
                                    : null,
                              );

                              if (results.isEmpty) {
                              return {
                                'success': false,
                                'message': '上传失败：无返回结果',
                                'code': 500,
                              };
                            }

                            final result = results.first;
                            if (result['success'] == true) {
                              final data =
                                  result['data'] as Map<String, dynamic>?;
                              return {
                                'success': true,
                                'data': data,
                                'statusCode': result['statusCode'] ?? 200,
                              };
                            } else {
                              return {
                                'success': false,
                                'message': result['message'] ?? '上传失败',
                                'code': result['code'] ?? 500,
                                'data': result['data'],
                              };
                            }
                            } finally {
                              if (mounted) setState(() => _isUploading = false);
                            }
                          } catch (e) {
                            return {
                              'success': false,
                              'message': '上传失败: $e',
                              'code': 500,
                            };
                          }
                        },
                      );
                    },

                    // -------------------------
                    // 页面开始加载
                    // -------------------------
                    onLoadStart: (_, __) {
                      setState(() => _isLoading = true);
                    },

                    // -------------------------
                    // 页面加载完成
                    // -------------------------
                    onLoadStop: (controller, url) async {
                      setState(() => _isLoading = false);

                      /// 注入 wx API
                      await controller.evaluateJavascript(
                        source: _injectWxJs(),
                      );

                      /// 注入通知和震动 Bridge
                      await controller.evaluateJavascript(
                        source: _injectNotificationVibrateJs(),
                      );

                      /// 同步 title
                      final title = await controller.getTitle();
                      if (title != null && title.isNotEmpty) {
                        setState(() => _webTitle = title);
                      }

                      if (widget.backForbid) {
                        controller.goBack();
                      }
                    },

                    // -------------------------
                    // 标题变化
                    // -------------------------
                    onTitleChanged: (_, title) {
                      if (title != null && title.isNotEmpty) {
                        setState(() => _webTitle = title);
                      }
                    },

                    // -------------------------
                    // URL 拦截
                    // -------------------------
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url.toString();

                      if (_shouldExit(url)) {
                        NavigatorUtil.pop(context);
                        return NavigationActionPolicy.CANCEL;
                      }

                      return NavigationActionPolicy.ALLOW;
                    },

                    // 位置权限：用中文提示框替代 WebView 默认的英文提示（仅 Android）
                    onGeolocationPermissionsShowPrompt:
                        (controller, origin) async {
                      if (!Platform.isAndroid || !mounted) return null;
                      final allow = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          title: const Text('获取位置'),
                          content: const Text(
                            '智惠装需要获取您的位置信息以提供地图选点服务，是否允许？',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('拒绝'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('允许'),
                            ),
                          ],
                        ),
                      );
                      return GeolocationPermissionShowPromptResponse(
                        origin: origin,
                        allow: allow ?? false,
                        retain: allow ?? false,
                      );
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_isUploading)
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              '上传中...',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // AppBar
  // -------------------------
  Widget _buildAppBar(Color bg, Color iconColor) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(0, top, 0, 10),
      color: bg,
      child: Row(
        children: [
          IconButton(
            icon: const BackButtonIcon(),
            color: iconColor,
            onPressed: () => _handleHybridBack(),
          ),
          Expanded(
            child: Text(
              _webTitle.isNotEmpty ? _webTitle : (widget.title ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(color: iconColor, fontSize: 18),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
