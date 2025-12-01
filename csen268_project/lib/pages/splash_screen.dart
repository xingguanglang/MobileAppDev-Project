import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 创建动画控制器，动画时长2秒
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 淡入动画：从0到1
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // 缩放动画：从0.8到1.0
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // 启动动画
    _controller.forward();

    // 动画结束后导航到登录页
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 延迟500ms后跳转，让用户看到完整的动画
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: const Text(
                  'EditFlow',
                  style: TextStyle(
                    fontFamily: 'Spline Sans',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1C17),
                    letterSpacing: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

