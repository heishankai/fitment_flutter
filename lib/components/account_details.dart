import 'package:flutter/material.dart';
import 'package:fitment_flutter/theme/app_colors.dart';

class AccountDetails extends StatelessWidget {
  final List<dynamic> details;

  const AccountDetails({super.key, required this.details});

  bool _isIncome(int type) => type == 1;

  String _money(dynamic value) =>
      (double.tryParse(value?.toString() ?? '0') ?? 0).toStringAsFixed(2);

  String _time(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final d = DateTime.parse(value);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '账户明细',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          details.isEmpty ? _empty() : _list(),
        ],
      ),
    );
  }

  Widget _empty() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text('暂无明细记录',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
      ),
    );
  }

  Widget _list() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: details.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final item = details[index];
          final type = item['type'] ?? 0;
          final income = _isIncome(type);
          final color =
              income ? AppColors.success : AppColors.warning;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: color,
                  child: Icon(
                    income ? Icons.add : Icons.remove,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description'] ?? item['type_text'] ?? '未知',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _time(item['createdAt']),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${income ? '+' : '-'}¥${_money(item['amount'])}',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
