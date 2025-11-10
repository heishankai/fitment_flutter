import 'package:flutter/material.dart';
import 'package:fitment_flutter/utils/screen_adapter_helper.dart';

/// 菜单项组件
class MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.px, vertical: 4.px),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8.px,
            offset: Offset(0, 2.px),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.px),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 16.px),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.px),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.px),
                  ),
                  child: Icon(icon, color: color, size: 22.px),
                ),
                SizedBox(width: 16.px),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.px,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20.px),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
