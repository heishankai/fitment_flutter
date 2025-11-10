import 'package:flutter/material.dart';

/// 收入页面
class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收入'),
      ),
      body: const Center(child: Text('收入')),
    );
  }
}
