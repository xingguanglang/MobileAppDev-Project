import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/export_screen.dart';
import '../pages/camera_page.dart';
import '../pages/editor_page.dart';
import '../pages/media_selection_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
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
  ],
);
