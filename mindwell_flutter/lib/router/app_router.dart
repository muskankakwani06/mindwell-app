import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/therapists_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/feedback_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (!auth.initialized) return null;
        final isAuth = auth.isAuthenticated;
        final path = state.uri.path;
        final publicPaths = ['/', '/login', '/signup'];
        if (!isAuth && !publicPaths.contains(path)) return '/login';
        if (isAuth && publicPaths.contains(path)) return '/dashboard';
        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LandingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/therapists',   builder: (_, __) => const TherapistsScreen()),
            GoRoute(path: '/appointments', builder: (_, __) => const AppointmentsScreen()),
            GoRoute(path: '/assessment',   builder: (_, __) => const AssessmentScreen()),
            GoRoute(path: '/groups',       builder: (_, __) => const GroupsScreen()),
            GoRoute(path: '/chat',         builder: (_, __) => const ChatScreen()),
            GoRoute(path: '/payment',      builder: (_, __) => const PaymentScreen()),
            GoRoute(path: '/feedback',     builder: (_, __) => const FeedbackScreen()),
          ],
        ),
      ],
    );
  }
}
