// lib/widgets/app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String location; // 我们在 ShellRoute 里传入 state.uri.path
  const AppShell({Key? key, required this.child, required this.location}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // ① 在这里把 /editor 加进来（顺序=底栏顺序）
  static const List<String> _routes = ['/', '/editor', '/settings'];

  void _syncIndex() {
    final loc = widget.location;
    // ② 允许匹配子路径：/editor/xxx 也归到 /editor 这个 tab
    final idx = _routes.indexWhere((r) => loc == r || loc.startsWith('$r/'));
    _currentIndex = (idx < 0) ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _syncIndex();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      setState(_syncIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,

      // ③ 底栏：三个按钮（Projects / Editor / Settings）
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            context.go(_routes[index]); // 按索引跳转到路由
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder_open),       label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_fix_high),     label: 'Editor'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
