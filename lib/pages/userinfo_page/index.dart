import 'package:flutter/material.dart';

class UserinfoPage extends StatefulWidget {
  const UserinfoPage({super.key});

  @override
  State<UserinfoPage> createState() => _UserinfoPageState();
}

class _UserinfoPageState extends State<UserinfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
      ),
      body: const Center(
        child: Text('用户信息'),
      ),
    );
  }
}
