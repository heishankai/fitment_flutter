import 'package:flutter/foundation.dart';

/// 模拟错误上报（可替换为 Sentry / 自有埋点等）。
class MockErrorReporter {
  MockErrorReporter._();

  static void reportFlutterError(FlutterErrorDetails details) {
    debugPrint(
      '[MockErrorReporter][Flutter] ${details.exceptionAsString()}',
    );
    if (details.stack != null) {
      debugPrint(details.stack.toString());
    }
  }

  static void reportPlatformError(Object error, StackTrace stack) {
    debugPrint('[MockErrorReporter][Platform] $error');
    debugPrint(stack.toString());
  }
}
