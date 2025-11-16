import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final bool cover;

  const LoadingWidget(
      {super.key,
      required this.child,
      required this.isLoading,
      this.cover = false});

  @override
  Widget build(BuildContext context) {
    return cover ? _coverWidget : normalWidget;
  }

  Widget get normalWidget => isLoading ? _loadingWidget : child;

  Widget get _loadingWidget => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  Widget get _coverWidget => Stack(
        children: [
          child,
          isLoading ? _loadingWidget : Container(),
        ],
      );
}
