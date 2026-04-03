import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/add_dish_screen.dart';
import 'screens/my_lists_screen.dart';
import 'screens/active_list_screen.dart';
import 'screens/shared_with_me_screen.dart';
import 'screens/share_collaborate_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/auth_provider.dart';

class AppRoutes {
  static const String login = '/login';
  static const String main = '/';
  static const String addDish = '/add-dish';
  static const String activeList = '/active-list';
  static const String share = '/share';
  static const String settings = '/settings';
}

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final currentPath = state.uri.toString();

      const publicPaths = [AppRoutes.login];
      final isOnPublicPage = publicPaths.contains(currentPath);

      if (!isLoggedIn && !isOnPublicPage) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isOnPublicPage) {
        return AppRoutes.main;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.main,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: '/my-lists',
            name: 'my-lists',
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const MyListsScreen()),
          ),
          GoRoute(
            path: '/shared',
            name: 'shared',
            pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SharedWithMeScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addDish,
        name: 'add-dish',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const AddDishScreen()),
      ),
      GoRoute(
        path: AppRoutes.activeList,
        name: 'active-list',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ActiveListScreen()),
      ),
      GoRoute(
        path: AppRoutes.share,
        name: 'share',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const ShareCollaborateScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => NoTransitionPage(key: state.pageKey, child: const SettingsScreen()),
      ),
    ],
  );
}
