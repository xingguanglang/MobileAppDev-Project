import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/cubits/project_cubit.dart';
import 'package:csen268_project/widgets/my_project_card.dart';
import 'package:csen268_project/widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectCubit>().state;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7FBF9),
        title: const Text(
          'Projects',
          style: TextStyle(
            fontFamily: 'Spline Sans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 23/18,
            letterSpacing: 0,
            color: Color(0xFF0D1C17),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'My Projects',
              style: TextStyle(
                fontFamily: 'Spline Sans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 28/22,
                letterSpacing: 0,
                color: Color(0xFF0D1C17),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return MyProjectCard(
                  title: project,
                  subtitle: 'Edited recently',
                  imageAsset: null, // replace with actual image resource path
                  onTap: () {
                    // TODO: click project card to enter detail page
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           context.push('/export'); // ✅ 跳轉到 Export UI
        },
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTabSelected: (index) {
            if (index == 3) {
            context.push('/export'); // ✅ 第四個 icon (share) 也能跳轉
          // TODO: jump or update status according to index
          }
        },
      ),
    );
  }
}
