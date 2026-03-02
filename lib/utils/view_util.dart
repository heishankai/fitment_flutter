import 'package:flutter/material.dart';

/// 间距
SizedBox hiSpace({double height = 1, double width = 1}) {
  return SizedBox(
    height: height,
    width: width,
  );
}

/// Toast 显示位置
enum ToastPosition {
  top,
  bottom,
}

/// 显示 Toast 提示，默认在顶部显示（避免被键盘遮挡）
void showToast(BuildContext context, String msg, {ToastPosition position = ToastPosition.top}) {
  if (position == ToastPosition.top) {
    _showTopToast(context, msg);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
    ));
  }
}

/// 在顶部显示 Toast（使用 Overlay，不会被键盘遮挡）
void _showTopToast(BuildContext context, String msg) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}
