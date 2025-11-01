// Flutter 核心组件库
import 'package:flutter/material.dart';

/// 应用程序入口点
/// 启动 Flutter 应用并运行 MyApp 组件
void main() {
  runApp(const MyApp());
}

/// 应用程序的根组件
/// 这是一个无状态的 Widget，负责配置应用的基本设置
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 构建应用程序的主界面
  /// 配置 Material Design 主题和应用的初始页面
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // 配置应用主题，使用深紫色作为种子颜色，启用 Material 3 设计
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 设置应用的首页
      home: const MyHomePage(title: '首页'),
    );
  }
}

/// 主页面组件
/// 这是一个有状态的 Widget，可以响应用户交互并更新界面
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  /// 页面标题
  final String title;

  /// 创建页面的状态对象
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// 主页面的状态类
/// 管理页面的状态数据和界面更新逻辑
class _MyHomePageState extends State<MyHomePage> {
  /// 计数器变量，用于记录按钮点击次数
  int _counter = 0;

  /// 增加计数器的方法
  /// 每次调用时，计数器值加 1，并触发界面更新
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// 构建页面的 UI 界面
  /// 包含应用栏、居中显示的计数器和浮动操作按钮
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 应用栏：显示页面标题
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      // 页面主体内容：居中显示的垂直布局
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 提示文本
            const Text(
              'You have pushed the button this many times:',
            ),
            // 显示当前计数器值
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      // 浮动操作按钮：点击后增加计数器
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
