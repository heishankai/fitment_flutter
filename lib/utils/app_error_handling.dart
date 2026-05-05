import 'package:fitment_flutter/theme/app_colors.dart';
import 'package:fitment_flutter/utils/mock_error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 全局错误处理：[ErrorWidget.builder] 兜底 UI + SnackBar 提示；
/// [FlutterError.onError] / [PlatformDispatcher.onError] 中做模拟上报。
class AppErrorHandling {
  AppErrorHandling._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static String? _lastSnackSignature;
  static DateTime? _lastSnackAt;

  static void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      MockErrorReporter.reportFlutterError(details);
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      MockErrorReporter.reportPlatformError(error, stack);
      return true;
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      // 上报已在 [FlutterError.onError] 中完成，此处仅做占位 UI + SnackBar 提示。
      _scheduleErrorSnackBar(details);
      return const _BuildErrorPlaceholder();
    };
  }

  static void _scheduleErrorSnackBar(FlutterErrorDetails details) {
    final signature = details.exceptionAsString();
    final now = DateTime.now();
    if (_lastSnackSignature == signature &&
        _lastSnackAt != null &&
        now.difference(_lastSnackAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastSnackSignature = signature;
    _lastSnackAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = scaffoldMessengerKey.currentState;
      if (messenger == null) return;

      final text = kReleaseMode
          ? '页面加载异常，请稍后重试'
          : '构建异常：${details.exceptionAsString()}';

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }
}

/// 构建失败时占位，避免整屏红块；具体说明由 SnackBar 承担。
class _BuildErrorPlaceholder extends StatelessWidget {
  const _BuildErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
