import 'package:flutter/material.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';

/// 编辑资料按钮组件
class EditProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const EditProfileButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48.px,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00CEC9), Color(0xFF00B4D8)],
        ),
        borderRadius: BorderRadius.circular(12.px),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00CEC9).withOpacity(0.3),
            blurRadius: 12.px,
            offset: Offset(0, 4.px),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.px),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, size: 18.px, color: Colors.white),
              SizedBox(width: 8.px),
              Text(
                '编辑资料',
                style: TextStyle(
                  fontSize: 16.px,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

