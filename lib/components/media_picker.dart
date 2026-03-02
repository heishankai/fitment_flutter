import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image_picker/image_picker.dart';

/// ---------------------------
/// 媒体类型 & 文件封装
/// ---------------------------
enum MediaType { image, video }

class MediaFile {
  final File file;
  final MediaType type;
  final String? thumbnailPath; // 视频缩略图可选

  MediaFile({required this.file, required this.type, this.thumbnailPath});
}

/// ---------------------------
/// 媒体选择器组件
/// ---------------------------
class MediaPicker {
  static final ImagePicker _picker = ImagePicker();

  /// 从上传结果中提取 URL
  /// 支持两种数据结构：
  /// 1. 直接返回数据：{url: ...}
  /// 2. 标准格式：{success: true, data: {url: ...}}
  static String? extractUrlFromUploadResult(Map<String, dynamic> uploadResult) {
    if (uploadResult['success'] != true) {
      return null;
    }

    final resultData = uploadResult['data'] as Map<String, dynamic>?;
    if (resultData == null) {
      return null;
    }

    // 先检查 resultData 本身是否有 url（直接返回数据的情况）
    if (resultData.containsKey('url')) {
      return resultData['url'] as String?;
    }

    // 检查是否有嵌套的 data 字段（标准格式：{success: true, data: {url: ...}}）
    if (resultData.containsKey('data')) {
      final nestedData = resultData['data'] as Map<String, dynamic>?;
      return nestedData?['url'] as String?;
    }

    return null;
  }

  /// 展示选择弹窗
  /// [videoOnly] 如果为 true，只显示视频选择选项，隐藏图片选项
  static Future<List<MediaFile>?> showPicker({
    required BuildContext context,
    int maxCount = 1,
    bool allowVideo = false,
    bool videoOnly = false,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
    int? videoMaxDuration,
  }) async {
    if (maxCount == 1) {
      return _showSinglePicker(
        context: context,
        allowVideo: allowVideo,
        videoOnly: videoOnly,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        videoMaxDuration: videoMaxDuration,
      );
    } else {
      return _showMultiPicker(
        context: context,
        maxCount: maxCount,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
  }

  /// 单选模式
  static Future<List<MediaFile>?> _showSinglePicker({
    required BuildContext context,
    required bool allowVideo,
    bool videoOnly = false,
    required int imageQuality,
    double? maxWidth,
    double? maxHeight,
    int? videoMaxDuration,
  }) async {
    final completer = Completer<List<MediaFile>?>();
    bool hasSelected = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaSourceDialog(
        allowVideo: allowVideo,
        videoOnly: videoOnly,
        onCameraTap: videoOnly
            ? null
            : () async {
                hasSelected = true;
                Navigator.pop(_);
                final media = await _pickImage(
                    source: ImageSource.camera,
                    imageQuality: imageQuality,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight);
                if (!completer.isCompleted)
                  completer.complete(media != null ? [media] : null);
              },
        onGalleryTap: videoOnly
            ? null
            : () async {
                hasSelected = true;
                Navigator.pop(_);
                final media = await _pickImage(
                    source: ImageSource.gallery,
                    imageQuality: imageQuality,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight);
                if (!completer.isCompleted)
                  completer.complete(media != null ? [media] : null);
              },
        onVideoTap: allowVideo
            ? () async {
                hasSelected = true;
                Navigator.pop(_);
                final media = await _pickVideo(maxDuration: videoMaxDuration);
                if (!completer.isCompleted)
                  completer.complete(media != null ? [media] : null);
              }
            : null,
        onCancel: () {
          hasSelected = true;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    ).then((_) {
      if (!hasSelected && !completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  /// 多选模式（只支持图片）
  static Future<List<MediaFile>?> _showMultiPicker({
    required BuildContext context,
    required int maxCount,
    required int imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final completer = Completer<List<MediaFile>?>();
    bool hasSelected = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaSourceDialog(
        allowVideo: false,
        onCameraTap: () async {
          hasSelected = true;
          Navigator.pop(_);
          final media = await _pickImage(
              source: ImageSource.camera,
              imageQuality: imageQuality,
              maxWidth: maxWidth,
              maxHeight: maxHeight);
          if (!completer.isCompleted)
            completer.complete(media != null ? [media] : null);
        },
        onGalleryTap: () async {
          hasSelected = true;
          Navigator.pop(_);
          final images = await _pickMultipleImages(
              maxCount: maxCount,
              imageQuality: imageQuality,
              maxWidth: maxWidth,
              maxHeight: maxHeight);
          if (!completer.isCompleted) completer.complete(images);
        },
        onCancel: () {
          hasSelected = true;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    ).then((_) {
      if (!hasSelected && !completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  /// 单张图片选择
  static Future<MediaFile?> _pickImage({
    required ImageSource source,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth ?? 800,
        maxHeight: maxHeight ?? 800,
      );
      if (file != null)
        return MediaFile(file: File(file.path), type: MediaType.image);
    } catch (e) {
      debugPrint('选择图片失败: $e');
    }
    return null;
  }

  /// 多张图片选择
  static Future<List<MediaFile>?> _pickMultipleImages({
    required int maxCount,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: maxWidth ?? 800,
        maxHeight: maxHeight ?? 800,
        imageQuality: imageQuality,
        limit: maxCount,
      );
      if (images != null)
        return images
            .map((f) => MediaFile(file: File(f.path), type: MediaType.image))
            .toList();
    } catch (e) {
      debugPrint('多选图片失败: $e');
    }
    return null;
  }

  /// 视频选择
  static Future<MediaFile?> _pickVideo({int? maxDuration}) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration:
            maxDuration != null ? Duration(seconds: maxDuration) : null,
      );
      if (file != null)
        return MediaFile(file: File(file.path), type: MediaType.video);
    } catch (e) {
      debugPrint('选择视频失败: $e');
    }
    return null;
  }

  /// 上传文件到服务器
  /// [mediaFiles] 要上传的媒体文件列表
  /// [uploadUrl] 上传接口的完整 URL（例如：'https://example.com/api/upload'）
  /// [fieldName] 文件字段名，默认为 'file'
  /// [headers] 自定义请求头（可选），如果不提供，会自动添加 Accept: application/json
  /// [extraFields] 额外的表单字段（可选）
  /// [onProgress] 上传进度回调（可选），参数为已上传字节数和总字节数
  /// 返回上传结果列表，每个元素对应一个文件的上传结果
  static Future<List<Map<String, dynamic>>> upload({
    required List<MediaFile> mediaFiles,
    required String uploadUrl,
    String fieldName = 'file',
    Map<String, String>? headers,
    Map<String, String>? extraFields,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (mediaFiles.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> results = [];

    // 如果只有一个文件，使用单文件上传
    if (mediaFiles.length == 1) {
      final result = await _uploadSingle(
        mediaFile: mediaFiles[0],
        uploadUrl: uploadUrl,
        fieldName: fieldName,
        headers: headers,
        extraFields: extraFields,
        onProgress: onProgress,
      );
      results.add(result);
      return results;
    }

    // 多个文件，逐个上传
    for (int i = 0; i < mediaFiles.length; i++) {
      final result = await _uploadSingle(
        mediaFile: mediaFiles[i],
        uploadUrl: uploadUrl,
        fieldName: fieldName,
        headers: headers,
        extraFields: extraFields,
        onProgress: onProgress != null
            ? (sent, total) => onProgress(sent, total)
            : null,
      );
      results.add(result);
    }

    return results;
  }

  /// 上传单个文件
  static Future<Map<String, dynamic>> _uploadSingle({
    required MediaFile mediaFile,
    required String uploadUrl,
    required String fieldName,
    Map<String, String>? headers,
    Map<String, String>? extraFields,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(uploadUrl);
      debugPrint('📡 上传文件 URI: $uri');
      debugPrint('📡 上传文件路径: ${mediaFile.file.path}');

      // 创建 multipart request
      var request = http.MultipartRequest('POST', uri);

      // 设置请求头
      request.headers['Accept'] = 'application/json';
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // 获取文件的 MIME 类型
      final mediaType = _getMediaType(mediaFile.file.path);
      debugPrint('📡 文件 MIME 类型: ${mediaType.toString()}');

      // 添加文件
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          mediaFile.file.path,
          contentType: mediaType,
        ),
      );

      // 添加额外的表单字段
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      // 发送请求
      final streamedResponse = await request.send();

      // 收集响应数据
      final List<int> responseBytes = [];

      // 如果有进度回调，在开始上传时调用
      if (onProgress != null) {
        final totalBytes = request.contentLength;
        // 由于 http 包不支持真正的上传进度监听，
        // 这里提供一个简化的进度提示：开始上传
        onProgress(0, totalBytes > 0 ? totalBytes : 1);
      }

      // 读取响应流并收集数据
      await for (final chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
      }

      // 如果有进度回调，在上传完成时调用
      if (onProgress != null) {
        final totalBytes = request.contentLength;
        onProgress(
            totalBytes > 0 ? totalBytes : 1, totalBytes > 0 ? totalBytes : 1);
      }

      // 手动构建 Response
      final response = http.Response.bytes(
        responseBytes,
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        request: streamedResponse.request,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );

      Utf8Decoder utf8Decoder = const Utf8Decoder();
      String responseBody = utf8Decoder.convert(response.bodyBytes);
      var result = json.decode(responseBody);

      debugPrint('📨 上传文件响应: $result');

      // 检查 HTTP 状态码
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': result,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? '上传文件失败',
          'code': response.statusCode,
          'data': result,
        };
      }
    } catch (e) {
      debugPrint('❌ 上传文件失败: $e');
      return {
        'success': false,
        'message': '网络错误，请检查网络连接: $e',
        'code': 500,
      };
    }
  }

  /// 获取文件的 MIME 类型
  static http_parser.MediaType _getMediaType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'gif':
        return http_parser.MediaType('image', 'gif');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'svg':
        return http_parser.MediaType('image', 'svg+xml');
      case 'mp4':
        return http_parser.MediaType('video', 'mp4');
      case 'mov':
        return http_parser.MediaType('video', 'quicktime');
      case 'avi':
        return http_parser.MediaType('video', 'x-msvideo');
      case 'pdf':
        return http_parser.MediaType('application', 'pdf');
      default:
        // 默认使用 jpeg
        return http_parser.MediaType('image', 'jpeg');
    }
  }
}

/// ---------------------------
/// 对话框组件
/// ---------------------------
class _MediaSourceDialog extends StatelessWidget {
  final bool allowVideo;
  final bool videoOnly;
  final Future<void> Function()? onCameraTap;
  final Future<void> Function()? onGalleryTap;
  final Future<void> Function()? onVideoTap;
  final VoidCallback? onCancel;

  const _MediaSourceDialog({
    required this.allowVideo,
    this.videoOnly = false,
    this.onCameraTap,
    this.onGalleryTap,
    this.onVideoTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCameraTap != null)
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('拍照'),
              onTap: onCameraTap,
            ),
          if (onGalleryTap != null)
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('从相册选择'),
              onTap: onGalleryTap,
            ),
          if (allowVideo && onVideoTap != null)
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.primary),
              title: const Text('选择视频'),
              onTap: onVideoTap,
            ),
          const Divider(height: 8, thickness: 8, color: AppColors.bgGrey),
          ListTile(
            title: const Text('取消', textAlign: TextAlign.center),
            onTap: () {
              Navigator.pop(context);
              onCancel?.call();
            },
          ),
        ],
      ),
    );
  }
}
