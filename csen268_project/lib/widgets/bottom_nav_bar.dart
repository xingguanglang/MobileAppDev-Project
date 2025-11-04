import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: Container(
        height: 53,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/bottom_nav_bar/folder.png',
                    width: 24,
                    height: 24,
                    color: currentIndex == 0 ? Colors.green : Colors.black,
                  ),
                  onPressed: () => _onTap(context, 0),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/bottom_nav_bar/camera.png',
                    width: 24,
                    height: 24,
                    color: currentIndex == 1 ? Colors.green : Colors.black,
                  ),
                  onPressed: () => _onTap(context, 1),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/bottom_nav_bar/edit.png',
                    width: 24,
                    height: 24,
                    color: currentIndex == 2 ? Colors.green : Colors.black,
                  ),
                  onPressed: () => _onTap(context, 2),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/bottom_nav_bar/share.png',
                    width: 24,
                    height: 24,
                    color: currentIndex == 3 ? Colors.green : Colors.black,
                  ),
                  onPressed: () => _onTap(context, 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/camera');
        break;
      case 2:
        context.go('/editor');
        break;
      case 3:
        context.push('/export');
        break;
      default:
        break;
    }
  }
}
