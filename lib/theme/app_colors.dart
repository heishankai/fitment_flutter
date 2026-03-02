import 'package:flutter/material.dart';

/// 智惠装 · 空间美学版主题色
/// 参考 fitment-mini-program uni.scss
/// 风格：克制 / 空间感 / 高级 / 设计品牌
class AppColors {
  AppColors._();

  /* ========================= */
  /* 行为相关颜色 */
  /* ========================= */

  /// 主品牌色（深青绿）
  static const Color primary = Color(0xFF2D635E);
  /// 成功（低饱和绿）
  static const Color success = Color(0xFF4F7A67);
  /// 警告（克制琥珀色）
  static const Color warning = Color(0xFFC89A57);
  /// 错误（低饱和红）
  static const Color error = Color(0xFFC46B6B);

  /* ========================= */
  /* 文字颜色 */
  /* ========================= */

  /// 一级标题（替代纯黑）
  static const Color textPrimary = Color(0xFF1E2222);
  /// 反色
  static const Color textInverse = Color(0xFFFFFFFF);
  /// 次级说明文字
  static const Color textGrey = Color(0xFF6E7373);
  /// 占位符
  static const Color textPlaceholder = Color(0xFFA8ADAD);
  /// 禁用状态
  static const Color textDisable = Color(0xFFC5C9C9);
  /// 副标题/段落
  static const Color textSubtitle = Color(0xFF444A4A);

  /* ========================= */
  /* 背景颜色 */
  /* ========================= */

  /// 主背景
  static const Color bg = Color(0xFFFFFFFF);
  /// 一级浅背景（区块分层）
  static const Color bgGrey = Color(0xFFF3F6F5);
  /// 点击状态背景
  static const Color bgHover = Color(0xFFE7EFEC);
  /// 遮罩
  static Color get bgMask => Colors.black.withOpacity(0.35);

  /* ========================= */
  /* 边框颜色 */
  /* ========================= */

  /// 分割线 / 边框（极轻）
  static const Color border = Color(0xFFE6EAEA);

  /* ========================= */
  /* 渐变辅助色（主色系） */
  /* ========================= */

  /// 主色渐变终点（与 success 同色系）
  static const Color primaryGradientEnd = Color(0xFF4F7A67);
}
