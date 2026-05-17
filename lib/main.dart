import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/group_chat_screen.dart';
import 'screens/bot_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/new_chat_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FluxApp());
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',         builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup',        builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/profile/setup', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/groups',        builder: (_, __) => const GroupsScreen()),
    GoRoute(path: '/bot',           builder: (_, __) => const BotScreen()),
    GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/new-chat',      builder: (_, __) => const NewChatScreen()),
    GoRoute(path: '/chat/:id',      builder: (_, s)  => ChatScreen(userId: s.pathParameters['id']!)),
    GoRoute(path: '/group/:id',     builder: (_, s)  => GroupChatScreen(groupId: s.pathParameters['id']!)),
    GoRoute(path: '/profile/:id',   builder: (_, s)  => ProfileScreen(userId: s.pathParameters['id']!)),
  ],
);

class FluxApp extends StatefulWidget {
  const FluxApp({super.key});
  @override
  State<FluxApp> createState() => _FluxAppState();
}

class _FluxAppState extends State<FluxApp> {
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FLUX',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}