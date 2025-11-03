import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
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
                  onPressed: () => onTabSelected(0),
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
                  onPressed: () => onTabSelected(1),
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
                  onPressed: () => onTabSelected(2),
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
                  onPressed: () => onTabSelected(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
