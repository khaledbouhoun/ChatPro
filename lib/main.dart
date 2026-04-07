import 'package:chat_pro/services/messagequeueservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/conversation_screen.dart';
import 'views/screens/chat_screen.dart';
import 'views/screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/hive_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await Get.putAsync(() => HiveService().init());
  await Get.putAsync(() => AuthService().init());
  await Get.putAsync(() => MessageQueueService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a lightweight startup decider so we can deterministically
    // route to `/login` when there's no session stored in Hive.
    return GetMaterialApp(
      title: 'Chat Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _RootDecider(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen(), transition: Transition.fade),
        GetPage(name: '/home', page: () => const ConversationListScreen(), transition: Transition.rightToLeftWithFade),
        GetPage(name: '/chat', page: () => const ChatScreen(), transition: Transition.downToUp),
        GetPage(name: '/profile', page: () => const ProfileScreen(), transition: Transition.rightToLeftWithFade),
      ],
    );
  }
}

class _RootDecider extends StatefulWidget {
  const _RootDecider({super.key});

  @override
  State<_RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<_RootDecider> {
  @override
  void initState() {
    super.initState();
    // Defer routing until after the first frame to ensure Get is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final hive = Get.find<HiveService>();
        final userId = hive.getCurrentUserId();
        if (userId == null) {
          Get.offAllNamed('/login');
        } else {
          Get.offAllNamed('/home');
        }
      } catch (e) {
        // If HiveService isn't available for some reason, fall back to login.
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimal empty container while we decide where to route.
    return const Scaffold(body: SizedBox.shrink());
  }
}
