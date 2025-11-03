// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'cubits/project_cubit.dart';
import 'widgets/app_shell.dart';
import 'pages/home_page.dart';
import 'pages/editor_page.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ProjectCubit>(
          create: (_) => ProjectCubit()
            // 如果你的 Cubit 有加载方法，在这里触发，比如：
            // ..loadProjects();
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            child: child,
            location: state.uri.path, // ← 用 uri.path 代替旧版的 state.location
          ),
          routes: [
            GoRoute(path: '/',        builder: (c, s) => const HomePage()),
            // GoRoute(path: '/settings',builder: (c, s) => const SettingsPage()),
            GoRoute(path: '/editor',  builder: (c, s) => const EditorPage()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4BAE61)),
        useMaterial3: true,
      ),
    );
  }
}
