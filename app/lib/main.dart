import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'features/auth/auth_provider.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Main] Firebase initialization notice: $e');
  }

  runApp(
    const ProviderScope(
      child: ChindiApp(),
    ),
  );
}

class ChindiApp extends ConsumerStatefulWidget {
  const ChindiApp({super.key});

  @override
  ConsumerState<ChindiApp> createState() => _ChindiAppState();
}

class _ChindiAppState extends ConsumerState<ChindiApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    final apiClient = ref.read(apiClientProvider);
    final router = ref.read(appRouterProvider);

    await NotificationService().init(
      apiClient: apiClient,
      onOpenGroupChat: (groupId) {
        if (groupId.isNotEmpty) {
          router.push('/chat/$groupId');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Chindi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
