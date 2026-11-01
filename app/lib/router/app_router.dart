import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../features/groups/groups_list_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/group_chat_screen.dart';
import '../features/report/cycle_history_detail_screen.dart';
import '../features/report/cycle_report_screen.dart';
import '../features/report/past_cycles_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final loc = state.matchedLocation;
    final isAuthenticated = authState.isAuthenticated;
    final isAuthRoute = loc == '/login' || loc == '/signup';

    // If authenticated and on login or signup screen, go to home
    if (isAuthenticated && isAuthRoute) {
      return '/';
    }

    // If not authenticated and trying to access a protected screen, redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsListScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupChatScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CycleReportScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/report/:id/history',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PastCyclesScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/cycles/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CycleHistoryDetailScreen(cycleId: id);
        },
      ),
    ],
  );
});
