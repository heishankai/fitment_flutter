import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fitment_flutter/utils/navigator_util.dart';
import 'package:fitment_flutter/dao/login_dao.dart';
import 'package:fitment_flutter/components/loading_widget.dart';
import 'package:fitment_flutter/pages/login_page/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// 文件选择类型
enum _FileSelectType { image, video }

/// 文件选择结果
class _FileSelectResult {
  final _FileSelectType type;
  final ImageSource? imageSource;
  
  _FileSelectResult({required this.type, this.imageSource});
}

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
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _currentUrl;
  PullToRefreshController? _pullToRefreshController;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  
  /// 处理返回键逻辑
  Future<bool> _handleBackButton() async {
    if (_webViewController == null) {
      debugPrint("⚠️ WebView 控制器未初始化，无法处理返回");
      return false;
    }
    
    try {
      // 检查 WebView 是否可以返回
      final canGoBack = await _webViewController?.canGoBack() ?? false;
      debugPrint("🔙 检查 WebView 返回状态: canGoBack=$canGoBack");
      
      if (canGoBack) {
        // WebView 可以返回，执行返回操作
        debugPrint("✅ WebView 可以返回，执行 goBack()");
        _webViewController?.goBack();
        
        // 等待 goBack() 完成，然后更新 URL（确保 TabNavigator 能检测到变化）
        Future.delayed(const Duration(milliseconds: 200)).then((_) async {
          try {
            final currentUrl = await _webViewController?.getUrl();
            if (currentUrl != null) {
              final urlString = currentUrl.toString();
              debugPrint("🔙 goBack() 后的 URL: $urlString");
              // 强制更新 URL，确保回调被触发
              if (_currentUrl != urlString) {
                _updateUrl(urlString);
              }
            }
          } catch (e) {
            debugPrint("⚠️ 获取 goBack() 后的 URL 失败: $e");
          }
        });
        
        return true; // 已处理，阻止默认行为（退出应用）
      } else {
        debugPrint("ℹ️ WebView 不能返回，将关闭当前页面");
      }
    } catch (e) {
      debugPrint("❌ 检查 WebView 返回状态失败: $e");
    }
    
    // WebView 不能返回，允许默认行为（关闭页面）
    return false;
  }

  /// 需要拦截的 URL
  final List<String> _catchUrls = [
    'https://www.zjiangyun.cn',
  ];

  @override
  void initState() {
    super.initState();
    // 延迟执行权限请求，避免在 initState 中立即执行导致问题
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestLocationPermission();
        _requestCameraPermission();
        _requestNotificationPermission();
        _initializeNotifications();
      }
    });
    _initPullToRefresh();
    _setStatusBarStyle();
  }

  @override
  void dispose() {
    // 恢复默认状态栏样式
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  /// 设置状态栏样式
  void _setStatusBarStyle() {
    // 这个方法会在 build 时通过 AnnotatedRegion 设置状态栏样式
  }

  void _initPullToRefresh() {
    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        await _webViewController?.reload();
      },
    );
  }

  /// 请求位置权限（Android 6.0+ 需要）
  void _requestLocationPermission() async {
    if (Platform.isAndroid) {
      await _ensureLocationPermission();
    }
  }

  /// 请求相机权限（用于拍照上传）
  void _requestCameraPermission() async {
    if (Platform.isAndroid) {
      try {
        // 延迟请求权限，避免在 initState 中立即请求导致问题
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 请求相机权限
        final cameraStatus = await Permission.camera.status;
        debugPrint("📷 相机权限状态: $cameraStatus");
        
        if (cameraStatus.isDenied) {
          debugPrint("📷 请求相机权限...");
          final cameraResult = await Permission.camera.request();
          debugPrint("📷 相机权限请求结果: $cameraResult");
        }
        
        // 请求存储权限（Android 10-12）
        try {
          final storageStatus = await Permission.storage.status;
          debugPrint("💾 存储权限状态: $storageStatus");
          
          if (storageStatus.isDenied) {
            debugPrint("💾 请求存储权限...");
            final storageResult = await Permission.storage.request();
            debugPrint("💾 存储权限请求结果: $storageResult");
          }
        } catch (e) {
          debugPrint("⚠️ 存储权限请求失败（可能不支持）: $e");
        }
        
        // Android 13+ 请求媒体权限
        try {
          final photosStatus = await Permission.photos.status;
          if (photosStatus.isDenied) {
            await Permission.photos.request();
          }
        } catch (e) {
          debugPrint("⚠️ 媒体权限请求失败（可能不支持）: $e");
        }
      } catch (e) {
        debugPrint("❌ 请求相机/存储权限失败: $e");
      }
    }
  }

  /// 确保位置权限已授予
  Future<void> _ensureLocationPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.location.status;
        debugPrint("📍 位置权限状态: $status");
        
        if (status.isDenied) {
          debugPrint("📍 请求位置权限...");
          final result = await Permission.location.request();
          debugPrint("📍 位置权限请求结果: $result");
          if (result.isGranted) {
            debugPrint("✅ 位置权限已授予");
          } else {
            debugPrint("⚠️ 位置权限被拒绝");
          }
        } else if (status.isPermanentlyDenied) {
          debugPrint("⚠️ 位置权限被永久拒绝，需要手动开启");
        } else if (status.isGranted) {
          debugPrint("✅ 位置权限已授予");
        }
      } catch (e) {
        debugPrint("❌ 请求位置权限失败: $e");
      }
    }
  }

  /// 请求通知权限
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        debugPrint("🔔 通知权限状态: $status");
        
        if (status.isDenied) {
          debugPrint("🔔 请求通知权限...");
          final result = await Permission.notification.request();
          debugPrint("🔔 通知权限请求结果: $result");
          if (result.isGranted) {
            debugPrint("✅ 通知权限已授予");
          } else {
            debugPrint("⚠️ 通知权限被拒绝");
          }
        } else if (status.isGranted) {
          debugPrint("✅ 通知权限已授予");
        }
      } catch (e) {
        debugPrint("❌ 请求通知权限失败: $e");
      }
    }
  }

  /// 初始化通知插件
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("🔔 通知被点击: ${details.payload}");
        },
      );
      
      _notificationsInitialized = true;
      debugPrint("✅ 通知插件初始化成功");
    } catch (e) {
      debugPrint("❌ 初始化通知插件失败: $e");
    }
  }

  /// 显示通知
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // 确保通知权限已授予
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          debugPrint("⚠️ 通知权限未授予，无法显示通知");
          return;
        }
      }
      
      // 确保通知插件已初始化
      if (!_notificationsInitialized) {
        await _initializeNotifications();
      }
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fitment_channel',
        '叮当师傅通知',
        channelDescription: '叮当师傅应用通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      debugPrint("✅ 通知已显示: $title - $body");
    } catch (e) {
      debugPrint("❌ 显示通知失败: $e");
    }
  }

  /// 处理通知请求
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
        debugPrint("⚠️ 通知参数格式错误");
        return;
      }
      
      final String title = params['title'] ?? '通知';
      final String body = params['body'] ?? '';
      final String? payload = params['payload'];
      
      await _showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint("❌ 处理通知请求失败: $e");
    }
  }

  /// 处理震动请求
  Future<void> _handleVibrate(dynamic args) async {
    try {
      int duration = 500; // 默认震动500毫秒
      
      if (args is List && args.isNotEmpty) {
        if (args[0] is num) {
          duration = args[0].toInt();
        } else if (args[0] is String) {
          final parsed = int.tryParse(args[0]);
          if (parsed != null) {
            duration = parsed;
          }
        } else if (args[0] is Map) {
          final params = args[0] as Map<String, dynamic>;
          if (params['duration'] != null) {
            duration = (params['duration'] as num).toInt();
          }
        }
      }
      
      // 限制震动时长在合理范围内（10ms - 5000ms）
      duration = duration.clamp(10, 5000);
      
      final bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: duration);
        debugPrint("✅ 震动成功，时长: ${duration}ms");
      } else {
        debugPrint("⚠️ 设备不支持震动");
      }
    } catch (e) {
      debugPrint("❌ 震动失败: $e");
    }
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

  /// 更新 URL + 回调
  void _updateUrl(String newUrl) {
    if (_currentUrl != newUrl) {
      _currentUrl = newUrl;
      widget.onUrlChanged?.call(newUrl);
    }
  }

  /// JS 调用 Flutter 的消息处理
  void _handleJSMessage(dynamic message) {
    try {
      debugPrint("📨 收到 H5 消息: $message");
      dynamic data;
      if (message is String) {
        if (message.startsWith('{') || message.startsWith('[')) {
          data = jsonDecode(message);
        } else {
          debugPrint("⚠️ 消息格式不是 JSON");
          return;
        }
      } else {
        data = message;
      }
      
      if (data is Map && data['action'] == 'logout') {
        debugPrint("✅ 处理退出登录请求");
        _handleLogout();
      } else {
        debugPrint("⚠️ 未知的 action: ${data['action']}");
      }
    } catch (e) {
      debugPrint("❌ 解析 H5 消息失败: $e");
      debugPrint("   消息内容: $message");
    }
  }

  /// 退出登录
  void _handleLogout() {
    LoginDao.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// 处理拍照请求
  Future<void> _handleTakePhoto() async {
    try {
      // 检查相机权限
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          debugPrint("❌ 相机权限未授予");
          return;
        }
      }

      // 使用 image_picker 拍照
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // 压缩质量
      );

      if (image == null) {
        debugPrint("⚠️ 用户取消了拍照");
        return;
      }

      // 读取图片文件并转换为 base64
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // 获取文件扩展名（通常是 jpg）
      final String extension = image.path.split('.').last.toLowerCase();
      final String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      
      // 构建 data URL
      final String dataUrl = 'data:$mimeType;base64,$base64Image';
      
      // 生成文件名（如果没有名称，使用时间戳）
      String fileName = image.name;
      if (fileName.isEmpty || !fileName.contains('.')) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'photo_$timestamp.${extension.isEmpty ? 'jpg' : extension}';
      }
      
      debugPrint("✅ 拍照成功，图片大小: ${imageBytes.length} bytes, 文件名: $fileName");
      
      // 将图片数据传给 H5
      await _sendImageToH5(dataUrl, fileName);
    } catch (e) {
      debugPrint("❌ 拍照失败: $e");
    }
  }

  /// 请求文件相关权限
  Future<void> _requestFilePermissions() async {
    if (Platform.isAndroid) {
      // 请求相机权限
      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        await Permission.camera.request();
      }
      
      // 请求相册权限（Android 13+ 使用 READ_MEDIA_IMAGES）
      if (Platform.version.contains('33') || Platform.version.contains('34') || Platform.version.contains('35')) {
        final photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          await Permission.photos.request();
        }
      } else {
        // Android 12 及以下使用存储权限
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }

  /// 显示文件源选择弹窗（拍照、相册、视频）
  Future<_FileSelectResult?> _showFileSourceDialog(BuildContext context, {String? accept}) {
    return showModalBottomSheet<_FileSelectResult>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, _FileSelectResult(type: _FileSelectType.image, imageSource: ImageSource.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('相册'),
                onTap: () => Navigator.pop(context, _FileSelectResult(type: _FileSelectType.image, imageSource: ImageSource.gallery)),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('视频'),
                onTap: () => Navigator.pop(context, _FileSelectResult(type: _FileSelectType.video)),
              ),
              ListTile(
                title: const Center(child: Text('取消')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 处理文件选择器请求
  Future<void> _handleFileChooser({String? accept}) async {
    try {
      debugPrint("📁 处理文件选择器请求，accept: $accept");
      
      // 请求权限
      await _requestFilePermissions();
      
      // 显示选择弹窗：拍照、相册或视频（根据 accept 决定是否显示视频）
      if (!context.mounted) return;
      final result = await _showFileSourceDialog(context, accept: accept);
      if (result == null) {
        debugPrint("⚠️ 用户取消了选择");
        return;
      }
      
      final ImagePicker picker = ImagePicker();
      XFile? file;
      
      if (result.type == _FileSelectType.image) {
        // 选择图片
        file = await picker.pickImage(
          source: result.imageSource!,
          imageQuality: 85,
        );
      } else if (result.type == _FileSelectType.video) {
        // 选择视频
        file = await picker.pickVideo(
          source: ImageSource.gallery,
        );
      }
      
      if (file == null) {
        debugPrint("⚠️ 未选择文件");
        return;
      }
      
      debugPrint("✅ 选择的文件路径: ${file.path}");
      
      // 判断是图片还是视频
      final String extension = file.path.split('.').last.toLowerCase();
      final bool isVideo = ['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(extension);
      
      if (isVideo) {
        // 处理视频文件
        await _sendVideoToH5(file);
      } else {
        // 处理图片文件
        // 读取图片文件并转换为 base64
        final Uint8List imageBytes = await file.readAsBytes();
        final String base64Image = base64Encode(imageBytes);
        
        // 获取文件扩展名
        final String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        
        // 构建 data URL
        final String dataUrl = 'data:$mimeType;base64,$base64Image';
        
        // 生成文件名
        String fileName = file.name;
        if (fileName.isEmpty || !fileName.contains('.')) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          fileName = 'photo_$timestamp.${extension.isEmpty ? 'jpg' : extension}';
        }
        
        debugPrint("✅ 图片选择成功，图片大小: ${imageBytes.length} bytes, 文件名: $fileName");
        
        // 将图片数据传给 H5
        await _sendImageToH5(dataUrl, fileName);
      }
    } catch (e) {
      debugPrint("❌ 处理文件选择失败: $e");
    }
  }
  
  /// 将视频文件发送给 H5
  Future<void> _sendVideoToH5(XFile videoFile) async {
    try {
      // 读取视频文件并转换为 base64
      final Uint8List videoBytes = await videoFile.readAsBytes();
      final String base64Video = base64Encode(videoBytes);
      
      // 获取文件扩展名和 MIME 类型
      final String extension = videoFile.path.split('.').last.toLowerCase();
      final String mimeType = extension == 'mp4' ? 'video/mp4' : 
                              extension == 'mov' ? 'video/quicktime' :
                              extension == 'avi' ? 'video/x-msvideo' :
                              'video/mp4'; // 默认 mp4
      
      // 构建 data URL
      final String dataUrl = 'data:$mimeType;base64,$base64Video';
      
      // 生成文件名
      String fileName = videoFile.name;
      if (fileName.isEmpty || !fileName.contains('.')) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = 'video_$timestamp.${extension.isEmpty ? 'mp4' : extension}';
      }
      
      debugPrint("✅ 视频选择成功，视频大小: ${videoBytes.length} bytes, 文件名: $fileName");
      
      // 使用通用的文件发送方法
      await _sendFileToH5(dataUrl, fileName, mimeType);
    } catch (e) {
      debugPrint("❌ 处理视频文件失败: $e");
    }
  }
  
  /// 将文件数据发送给 H5（通用方法，支持图片和视频）
  Future<void> _sendFileToH5(String dataUrl, String fileName, String mimeType) async {
    try {
      // 转义 JavaScript 字符串中的特殊字符
      final escapedDataUrl = dataUrl.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\n', '\\n').replaceAll('\r', '\\r');
      final escapedFileName = fileName.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
      final escapedMimeType = mimeType.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
      
      final js = '''
        (function() {
          try {
            console.log('📁 开始处理 Flutter 传来的文件: $escapedFileName, 类型: $escapedMimeType');
            
            // 将 base64 data URL 转换为 Blob
            function dataURLtoBlob(dataUrl) {
              const arr = dataUrl.split(',');
              const mimeMatch = arr[0].match(/:(.*?);/);
              const mime = mimeMatch ? mimeMatch[1] : '$escapedMimeType';
              const bstr = atob(arr[1]);
              let n = bstr.length;
              const u8arr = new Uint8Array(n);
              while (n--) {
                u8arr[n] = bstr.charCodeAt(n);
              }
              return new Blob([u8arr], { type: mime });
            }
            
            // 将 Blob 转换为 File
            function blobToFile(blob, fileName) {
              return new File([blob], fileName, { type: blob.type });
            }
            
            // 查找所有 input[type="file"] 元素
            const fileInputs = document.querySelectorAll('input[type="file"]');
            
            if (fileInputs.length === 0) {
              console.warn('⚠️ 页面中没有找到 input[type="file"] 元素');
              return;
            }
            
            // 创建 Blob 和 File 对象
            const blob = dataURLtoBlob('$escapedDataUrl');
            const file = blobToFile(blob, '$escapedFileName');
            
            // 找到最近点击的 input（通过查找空的 van-uploader）
            let targetInput = null;
            const uploaders = document.querySelectorAll('.van-uploader');
            
            if (uploaders.length > 0) {
              // 查找空的 uploader（没有预览的）
              const emptyUploaders = Array.from(uploaders).filter(function(uploader) {
                const preview = uploader.querySelector('.van-uploader__preview');
                return !preview || preview.children.length === 0;
              });
              
              if (emptyUploaders.length > 0) {
                // 使用第一个空的 uploader
                targetInput = emptyUploaders[0].querySelector('input[type="file"]');
              } else {
                // 如果没有空的，使用第一个 uploader
                targetInput = uploaders[0].querySelector('input[type="file"]');
              }
            } else {
              // 如果没有 van-uploader，使用第一个 input[type="file"]
              targetInput = fileInputs[0];
            }
            
            if (!targetInput) {
              console.warn('⚠️ 无法找到目标 input 元素');
              return;
            }
            
            // 创建 DataTransfer 对象来模拟文件选择
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);
            
            // 设置 files
            targetInput.files = dataTransfer.files;
            
            // 触发 change 事件（van-uploader 会监听这个事件）
            const changeEvent = new Event('change', { bubbles: true, cancelable: true });
            targetInput.dispatchEvent(changeEvent);
            
            // 也触发 input 事件（某些情况下可能需要）
            const inputEvent = new Event('input', { bubbles: true, cancelable: true });
            targetInput.dispatchEvent(inputEvent);
            
            console.log('✅ 已模拟文件选择事件，文件名: $escapedFileName');
          } catch (error) {
            console.error('❌ 处理 Flutter 文件失败:', error);
          }
        })();
      ''';
      
      await _webViewController?.evaluateJavascript(source: js);
      debugPrint("✅ 文件数据已发送给 H5，文件名: $fileName");
    } catch (e) {
      debugPrint("❌ 发送文件数据给 H5 失败: $e");
    }
  }

  /// 注入文件选择器拦截代码
  void _injectFileChooserInterceptor() async {
    const js = '''
      (function() {
        // 检查是否在 Flutter 环境中
        if (!window.flutter_inappwebview || !window.flutter_inappwebview.callHandler) {
          console.log('⚠️ 不在 Flutter 环境中，不拦截文件选择器');
          return;
        }
        
        // 拦截所有 input[type="file"] 的点击事件
        function interceptFileInputs() {
          const fileInputs = document.querySelectorAll('input[type="file"]');
          fileInputs.forEach(function(input) {
            // 检查是否已经添加过拦截器（避免重复添加）
            if (input.dataset.flutterIntercepted === 'true') {
              return;
            }
            
            // 标记已拦截
            input.dataset.flutterIntercepted = 'true';
            
            // 添加点击拦截（使用捕获阶段，确保先执行）
            input.addEventListener('click', function(e) {
              // 再次检查是否在 Flutter 环境中
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                try {
                  console.log('📁 拦截文件选择器，调用 Flutter 文件选择');
                  // 先阻止默认行为
                  e.preventDefault();
                  e.stopPropagation();
                  
                  // 获取 input 的 accept 属性
                  const accept = input.getAttribute('accept') || '';
                  console.log('📁 input accept 属性:', accept);
                  
                  // 调用 Flutter 的文件选择 handler，传递 accept 属性
                  window.flutter_inappwebview.callHandler('FlutterChooseFile', accept).then(function() {
                    console.log('✅ FlutterChooseFile 调用成功');
                  }).catch(function(err) {
                    console.error('❌ 调用 FlutterChooseFile 失败:', err);
                    // 如果调用失败，恢复默认行为
                    // 创建一个新的事件来触发文件选择器
                    setTimeout(function() {
                      const clickEvent = new MouseEvent('click', {
                        bubbles: true,
                        cancelable: true,
                        view: window
                      });
                      input.dispatchEvent(clickEvent);
                    }, 100);
                  });
                } catch (err) {
                  console.error('❌ 拦截文件选择器失败:', err);
                  // 如果出错，恢复默认行为
                  setTimeout(function() {
                    const clickEvent = new MouseEvent('click', {
                      bubbles: true,
                      cancelable: true,
                      view: window
                    });
                    input.dispatchEvent(clickEvent);
                  }, 100);
                }
              }
            }, true); // 使用捕获阶段，确保先执行
          });
        }
        
        // 立即执行一次
        interceptFileInputs();
        
        // 监听 DOM 变化，拦截动态添加的文件输入
        const observer = new MutationObserver(function(mutations) {
          interceptFileInputs();
        });
        
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
        
        console.log('✅ 文件选择器拦截器已注入');
      })();
    ''';
    
    try {
      await _webViewController?.evaluateJavascript(source: js);
      debugPrint("✅ 文件选择器拦截代码已注入");
    } catch (e) {
      debugPrint("❌ 注入文件选择器拦截代码失败: $e");
    }
  }

  /// 将图片数据发送给 H5（模拟文件选择事件）
  Future<void> _sendImageToH5(String dataUrl, String fileName) async {
    // 获取 MIME 类型
    final String mimeType = fileName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    await _sendFileToH5(dataUrl, fileName, mimeType);
  }

  /// 注入 JS → 提供 "window.AppLogout()"、"FlutterBridge.postMessage()"、"window.FlutterTakePhoto()"、"window.FlutterShowNotification()" 和 "window.FlutterVibrate()" 给 H5 调用
  void _injectFlutterLogoutBridge() async {
    const js = '''
      (function() {
        // 创建 FlutterBridge 对象来兼容旧的调用方式
        if (!window.FlutterBridge) {
          window.FlutterBridge = {
            postMessage: function(message) {
              if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                window.flutter_inappwebview.callHandler('FlutterBridge', message);
              }
            }
          };
        }
        
        // 提供 AppLogout 方法
        window.AppLogout = function() {
          var message = JSON.stringify({ action: 'logout' });
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('FlutterBridge', message);
          } else if (window.FlutterBridge) {
            window.FlutterBridge.postMessage(message);
          }
        };
        
        // 提供拍照方法
        window.FlutterTakePhoto = function() {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('FlutterTakePhoto');
          } else {
            console.warn('⚠️ FlutterTakePhoto 不可用');
          }
        };
        
        // 提供通知方法
        // 用法: window.FlutterShowNotification({ title: '标题', body: '内容', payload: '可选数据' })
        window.FlutterShowNotification = function(params) {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            if (typeof params === 'string') {
              // 如果传入的是字符串，尝试解析为JSON
              try {
                params = JSON.parse(params);
              } catch (e) {
                console.error('❌ 通知参数解析失败:', e);
                return;
              }
            }
            window.flutter_inappwebview.callHandler('FlutterShowNotification', params);
          } else {
            console.warn('⚠️ FlutterShowNotification 不可用');
          }
        };
        
        // 提供震动方法
        // 用法: window.FlutterVibrate(500) 或 window.FlutterVibrate({ duration: 500 })
        window.FlutterVibrate = function(duration) {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            if (typeof duration === 'number') {
              window.flutter_inappwebview.callHandler('FlutterVibrate', duration);
            } else if (typeof duration === 'object' && duration !== null) {
              window.flutter_inappwebview.callHandler('FlutterVibrate', duration);
            } else {
              // 默认震动500ms
              window.flutter_inappwebview.callHandler('FlutterVibrate', 500);
            }
          } else {
            console.warn('⚠️ FlutterVibrate 不可用');
          }
        };
        
        console.log('✅ FlutterBridge、AppLogout、FlutterTakePhoto、FlutterShowNotification 和 FlutterVibrate 已注入');
      })();
    ''';

    try {
      await _webViewController?.evaluateJavascript(source: js);
      debugPrint("✅ 注入 AppLogout、FlutterBridge、FlutterTakePhoto、FlutterShowNotification 和 FlutterVibrate 成功");
    } catch (e) {
      debugPrint("❌ 注入 JavaScript Bridge 失败: $e");
    }
  }

  /// SPA URL 轮询监听
  void _startUrlPolling() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    try {
      final url = await _webViewController?.getUrl();
      if (url != null) {
        final urlString = url.toString();
        if (_currentUrl != urlString) {
          debugPrint("🔄 URL 轮询检测到变化: $_currentUrl -> $urlString");
          _updateUrl(urlString);
        }
      }
    } catch (e) {
      debugPrint("⚠️ URL 轮询出错: $e");
    }

    _startUrlPolling();
  }

  @override
  Widget build(BuildContext context) {
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
    
    // 确保 _currentUrl 不为空
    if (_currentUrl == null || _currentUrl!.isEmpty) {
      debugPrint("❌ URL 为空，使用默认 URL");
      _currentUrl = url;
    }

    final statusColor =
        Color(int.parse("0xff${widget.statusBarColor ?? 'ffffff'}"));
    final backColor =
        widget.statusBarColor == 'ffffff' ? Colors.black : Colors.white;
    final isLight = widget.statusBarColor == 'ffffff';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        debugPrint("🔙 ========== PopScope 被触发（Android 返回键/滑动返回）==========");
        
        // 使用统一的返回处理逻辑
        final handled = await _handleBackButton();
        
        if (handled) {
          // WebView 已经处理了返回，不需要做其他操作
          debugPrint("✅ WebView 已处理返回，阻止退出应用");
          return;
        }
        
        // WebView 不能返回，检查是否可以关闭当前页面
        if (!context.mounted) {
          debugPrint("⚠️ Context 已销毁，无法处理返回");
          return;
        }
        
        // 检查是否是根路由（TabNavigator）
        final canPop = Navigator.canPop(context);
        debugPrint("🔙 Navigator.canPop: $canPop");
        
        if (canPop) {
          // 可以 pop，关闭当前页面
          debugPrint("✅ 关闭当前页面");
          Navigator.pop(context);
        } else {
          // 不能 pop，说明是根页面（TabNavigator），不应该退出应用
          debugPrint("⚠️ 当前是根页面，不执行任何操作，阻止退出应用");
          // 什么都不做，阻止退出应用
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // 透明状态栏
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent, // 透明导航栏
          systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        ),
      child: Scaffold(
          backgroundColor: Colors.white, // 设置 Scaffold 背景为白色
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
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_currentUrl!)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    // 启用文件上传
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    // Android 特定设置
                    useHybridComposition: true,
                    useShouldOverrideUrlLoading: true,
                    useOnLoadResource: true,
                    // 支持地理位置
                    geolocationEnabled: true,
                    // 支持文件访问（重要：相机拍照上传需要）
                    allowFileAccess: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    // 支持内容 URI（相机拍照返回的是 content:// URI）
                    allowContentAccess: true,
                  ),
                  pullToRefreshController: _pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    // 在 WebView 创建时就注册 JavaScript handler
                    controller.addJavaScriptHandler(
                      handlerName: 'FlutterBridge',
                      callback: (args) {
                        if (args.isNotEmpty) {
                          _handleJSMessage(args[0]);
                        }
                      },
                    );
                    // 注册拍照 handler
                    controller.addJavaScriptHandler(
                      handlerName: 'FlutterTakePhoto',
                      callback: (args) {
                        _handleTakePhoto();
                      },
                    );
                    // 注册文件选择 handler
                    controller.addJavaScriptHandler(
                      handlerName: 'FlutterChooseFile',
                      callback: (args) async {
                        await _handleFileChooser();
                      },
                    );
                    // 注册通知 handler
                    controller.addJavaScriptHandler(
                      handlerName: 'FlutterShowNotification',
                      callback: (args) async {
                        await _handleShowNotification(args);
                      },
                    );
                    // 注册震动 handler
                    controller.addJavaScriptHandler(
                      handlerName: 'FlutterVibrate',
                      callback: (args) async {
                        await _handleVibrate(args);
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    _updateUrl(url.toString());
                    setState(() => _isLoading = true);
                  },
                  onLoadStop: (controller, url) async {
                    _updateUrl(url.toString());
                    // 确保位置权限已授予
                    await _ensureLocationPermission();
                    // 注入 JavaScript Bridge（handler 已在 onWebViewCreated 中注册）
                    _injectFlutterLogoutBridge();
                    // 注入文件选择器拦截代码
                    _injectFileChooserInterceptor();
                    _startUrlPolling();
                    setState(() => _isLoading = false);
                  },
                  // 处理地理位置权限请求
                  onGeolocationPermissionsShowPrompt: (controller, origin) async {
                    // 确保权限已授予
                    final status = await Permission.location.status;
                    if (status.isGranted) {
                      return GeolocationPermissionShowPromptResponse(
                        origin: origin,
                        allow: true,
                        retain: true,
                      );
                    } else {
                      // 请求权限
                      final result = await Permission.location.request();
                      return GeolocationPermissionShowPromptResponse(
                        origin: origin,
                        allow: result.isGranted,
                        retain: result.isGranted,
                      );
                    }
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url.toString();
                    _updateUrl(url);

                    /// 命中需要拦截的 URL → 返回 Flutter
                    if (_catchUrls.any((u) => url.endsWith(u))) {
                      NavigatorUtil.pop(context);
                      return NavigationActionPolicy.CANCEL;
                    }

                    /// token 自动补齐
                    final token = LoginDao.getToken();
                    if (token != null &&
                        !Uri.parse(url).queryParameters.containsKey('token')) {
                      final newUrl = _addToken(url);
                      controller.loadUrl(urlRequest: URLRequest(url: WebUri(newUrl)));
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint("Console: ${consoleMessage.message}");
                  },
                  // JavaScript 处理器 - 处理 FlutterBridge.postMessage
                  onReceivedServerTrustAuthRequest: (controller, challenge) async {
                    return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
                final handled = await _handleBackButton();
                if (!handled && context.mounted) {
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
