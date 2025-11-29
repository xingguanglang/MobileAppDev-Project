import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/export_screen.dart';
import '../pages/camera_page.dart';
import '../pages/editor/editor_page.dart';
import '../pages/media_selection_page.dart';
import '../pages/register_page.dart';
import '../pages/login_page.dart';
import '../pages/user_page.dart';
import '../pages/project_detail_page.dart';
import '../cubits/user_cubit.dart';
import '../cubits/project_cubit.dart';
import '../repositories/project_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/export_request.dart';
import 'package:flutter/widgets.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

final GoRouter appRouter = GoRouter(
  observers: [routeObserver],
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
      routes: [
        GoRoute(
          path: 'media-selection',
          name: 'media-selection',
          builder: (context, state) {
            // create a separate ProjectCubit for media-selection
            final userId = context.read<UserCubit>().state.user?.id;
            if (userId == null) {
              throw Exception('User must be signed in before selecting media');
            }
            return BlocProvider(
              create: (_) {
                final cubit = ProjectCubit(ProjectRepository(userId: userId));
                cubit.loadProjects();
                return cubit;
              },
              child: const MediaSelectionPage(),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => const CameraPage(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      // builder: (context, state) => const EditorPage(),
      builder: (context, state) {
        // Get selected media paths from extra
        final selectedMediaPaths = state.extra as List<String>? ?? [];
        return EditorPage(selectedMediaPaths: selectedMediaPaths);
      },
    ),
    GoRoute(
      path: '/export',
      name: 'export',
      builder: (context, state) {
        final extra = state.extra;
        final request = extra is ExportRequest ? extra : null;
        return ExportScreen(request: request);
      },
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
        final extra = state.extra as Map<String, dynamic>?;
        final projectId = extra?['id'] as String?;
        final imageUrl = extra?['imageUrl'] as String?;
        if (projectId == null) {
          throw Exception('Project ID is required');
        }
        return BlocProvider(
          create: (_) {
            final userId = context.read<UserCubit>().state.user?.id;
            if (userId == null) throw Exception('User must be signed in before viewing project details');
            final cubit = ProjectCubit(ProjectRepository(userId: userId));
            cubit.loadProjects();
            return cubit;
          },
          child: ProjectDetailPage(
            projectId: projectId,
            imageUrl: imageUrl,
          ),
        );
      },
    ),
  ],
);
