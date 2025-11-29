import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:csen268_project/cubits/project_cubit.dart';
import 'package:csen268_project/widgets/my_project_card.dart';
import 'package:csen268_project/widgets/bottom_nav_bar.dart';
import '../routes/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    context.read<ProjectCubit>().loadProjects();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // when the user goes back to the home page from the project detail page, reload the projects
    context.read<ProjectCubit>().loadProjects();
  }

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
              'assets/icons/avatar.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              context.push('/user');
            },
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
                  title: project.name,
                  subtitle: 'Edited recently',
                  imageUrl: project.imageUrl,
                  onTap: () {
                    context.push(
                      '/project-detail',
                      extra: {
                        'id': project.id,
                        'imageUrl': project.imageUrl,
                      },
                    );
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
          // use push to stack the media selection page, so that the user can go back to the home page by clicking the back button
          context.push('/media-selection');
        },
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}
