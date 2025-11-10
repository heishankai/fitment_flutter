import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 输入框，自定义widget
class InputWidget extends StatelessWidget {
  // 输入框提示文字
  final String hint;
  // 输入框内容变化回调
  final ValueChanged<String>? onChanged;
  // 是否隐藏输入内容
  final bool obscureText;
  // 输入框类型
  final TextInputType keyboardType;
  // 焦点控制
  final FocusNode? focusNode;
  // 是否自动聚焦
  final bool autofocus;
  // 最大长度
  final int? maxLength;
  // 输入格式化
  final List<TextInputFormatter>? inputFormatters;
  // 文本对齐
  final TextAlign textAlign;
  // 文本控制器
  final TextEditingController? controller;

  const InputWidget({
    super.key,
    this.hint = '请输入',
    this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _input(),
    ]);
  }

  Widget _input() {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofocus: autofocus, // 是否自动聚焦
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      cursorColor: const Color(0xFF00CEC9), // 光标颜色使用主题色
      // 输入框文字颜色 大小 字体
      style: const TextStyle(
          color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey[400], fontSize: 17, fontWeight: FontWeight.w400),
        // 内容内边距
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        counterText: '', // 隐藏字符计数
        // 统一的椭圆形边框样式（浅灰色）
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // 大圆角实现椭圆形效果
          borderSide: BorderSide(
            color: Colors.grey[300]!, // 浅灰色边框
            width: 1,
          ),
        ),
        // 聚焦时也使用相同的浅灰色边框，避免显示主题色
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.grey[300]!, // 浅灰色边框
            width: 1,
          ),
        ),
        // 填充背景色（可选）
        filled: true,
        fillColor: Colors.grey[50], // 浅灰色背景
      ),
    );
  }
}
