// 中国大陆（东八区，无夏令时）日期时间展示。
// 不依赖手机系统时区；无时区字符串按东八区墙钟理解（国内接口常见）。

bool _hasExplicitTimeZone(String s) {
  final t = s.trim();
  if (t.endsWith('Z') || t.endsWith('z')) return true;
  return RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t) ||
      RegExp(r'[+-]\d{4}$').hasMatch(t); // +0800
}

/// 解析为绝对时刻（UTC）。
DateTime _parseToUtcInstant(String s) {
  final t = s.trim();
  if (t.isEmpty) throw const FormatException('empty');
  if (_hasExplicitTimeZone(t)) {
    return DateTime.parse(t).toUtc();
  }
  final norm = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  return DateTime.parse('$norm+08:00').toUtc();
}

/// 将 [instant] 格式化为东八区墙钟时间的 `yyyy-MM-dd HH:mm`。
String _formatChinaWall(DateTime instant) {
  final w = instant.toUtc().add(const Duration(hours: 8));
  return '${w.year}-${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')} '
      '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}

/// [value]：ISO 8601 字符串、无时区字符串（按东八区理解）、或 Unix 时间戳（秒/毫秒）。
String formatMainlandChinaDateTime(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    var ms = value.round();
    if (ms.abs() < 100000000000) ms *= 1000;
    return _formatChinaWall(
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));
  }
  final s = value.toString().trim();
  if (s.isEmpty) return '';
  if (RegExp(r'^-?\d+$').hasMatch(s)) {
    var ms = int.parse(s);
    if (s.length <= 10) ms *= 1000;
    return _formatChinaWall(
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));
  }
  try {
    return _formatChinaWall(_parseToUtcInstant(s));
  } catch (_) {
    return '';
  }
}
