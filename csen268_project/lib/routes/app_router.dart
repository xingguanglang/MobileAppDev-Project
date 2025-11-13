import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/export_screen.dart';
import '../pages/camera_page.dart';
import '../pages/editor_page.dart';
import '../pages/media_selection_page.dart';
import '../pages/register_page.dart';
import '../pages/login_page.dart';
import '../pages/user_page.dart';
import '../pages/project_detail_page.dart';
import '../cubits/user_cubit.dart';
import '../cubits/project_cubit.dart';
import '../repositories/project_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) {
        final userId = context.read<UserCubit>().state.user?.id;
        if (userId == null) {
          throw Exception('User must be signed in before loading projects');
        }
        return BlocProvider(
          create: (_) {
            final cubit = ProjectCubit(ProjectRepository(userId: userId));
            cubit.loadProjects();
            return cubit;
          },
          child: const HomePage(),
        );
      },
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => const CameraPage(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) => const EditorPage(),
    ),
    GoRoute(
      path: '/media-selection',
      name: 'media-selection',
      builder: (context, state) => const MediaSelectionPage(),
    ),
    GoRoute(
      path: '/export',
      name: 'export',
      builder: (context, state) => const ExportScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/user',
      name: 'user',
      builder: (context, state) => const UserPage(),
    ),
    GoRoute(
      path: '/project-detail',
      name: 'project-detail',
      builder: (context, state) {
        final imageUrl = state.extra as String?;
        return ProjectDetailPage(imageUrl: imageUrl);
      },
    ),
  ],
);
