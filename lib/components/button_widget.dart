import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String title;
  final bool enable;
  final VoidCallback? onPressed;

  const ButtonWidget(
      {super.key, required this.title, this.enable = true, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enable ? onPressed : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: enable
                ? const LinearGradient(
                    begin: Alignment.topLeft, // 45deg 从左上到右下
                    end: Alignment.bottomRight,
                    stops: [0.0, 1.0],
                    colors: [
                      Color(0xFF00CEC9), // #00cec9
                      Color(0xFF00B4D8), // #00b4d8
                    ],
                  )
                : null,
            color: enable ? null : const Color(0xFFB2F7F5),
            borderRadius: BorderRadius.circular(30),
            boxShadow: enable
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: enable ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
