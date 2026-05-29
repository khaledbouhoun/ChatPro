import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// Only import dart:html on web platform to avoid compilation errors on other platforms
import 'dart:html' as html show window;

import '../controllers/chat_controller.dart';
import 'hive_service.dart';

class FCMService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final HiveService _hiveService = Get.find<HiveService>();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _clickSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription? _windowMessageSubscription;

  // IMPORTANT: Replace this VAPID key with your actual web push certificate public key from Firebase Console
  // Path: Firebase Console -> Project Settings -> Cloud Messaging -> Web Configuration -> Web Push Certificates
  static const String vapidKey = "BMJo16Na2kHdh3ufPN4TE8oKvfkKTqpHyRD0fAqNKBKwk2gjFbvZB7PosdcvY7oDPKRhK4XTZ971vMHyNXrXzFw";

  Future<FCMService> init() async {
    debugPrint('[FCMService] Initializing...');

    if (kIsWeb) {
      _setupServiceWorkerMessageListener();
    }

    _setupForegroundMessageListener();
    _setupNotificationClickListeners();

    // If a user is already authenticated (e.g. session restored), register token
    final currentUserId = _hiveService.getCurrentUserId();
    if (currentUserId != null) {
      await registerFCM(currentUserId);
    }

    return this;
  }

  @override
  void onClose() {
    _foregroundSubscription?.cancel();
    _clickSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _windowMessageSubscription?.cancel();
    super.onClose();
  }

  // ─── Permission & Registration ─────────────────────────────────────────────

  /// Requests permissions and registers FCM token in Firestore under current user.
  Future<void> registerFCM(String userId) async {
    try {
      // 1. Request Browser/System Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCMService] User granted notification permissions.');

        // 2. Fetch and store current token
        await _fetchAndStoreToken(userId);

        // 3. Setup token refresh listener
        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
          _storeTokenInFirestore(userId, newToken);
        });
      } else {
        debugPrint('[FCMService] Notification permissions denied or not determined.');
      }
    } catch (e) {
      debugPrint('[FCMService] Error during registration: $e');
    }
  }

  // ─── Token Lifecycle management ───────────────────────────────────────────

  Future<void> _fetchAndStoreToken(String userId) async {
    try {
      String? token;
      if (kIsWeb) {
        // Web requires passing VAPID key
        token = await _messaging.getToken(vapidKey: vapidKey.contains("YOUR_VAPID") ? null : vapidKey);
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        await _storeTokenInFirestore(userId, token);
      } else {
        debugPrint('[FCMService] FCM Token is null.');
      }
    } catch (e) {
      debugPrint('[FCMService] Failed to retrieve FCM token: $e');
    }
  }

  Future<void> _storeTokenInFirestore(String userId, String token) async {
    try {
      // Use the token hash or a URL-safe version of the token as document ID to prevent duplicate listings
      final tokenDocId = token.hashCode.toString();

      final String userAgent = kIsWeb ? html.window.navigator.userAgent : 'mobile_app';

      await _firestore.collection('users').doc(userId).collection('fcm_tokens').doc(tokenDocId).set({
        'token': token,
        'platform': kIsWeb ? 'web' : 'mobile',
        'device_info': userAgent,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[FCMService] FCM Token successfully stored in Firestore.');
    } catch (e) {
      debugPrint('[FCMService] Error storing FCM token in Firestore: $e');
    }
  }

  /// Cleans up token from Firestore upon logout to prevent sending notifications to an unauthenticated device
  Future<void> unregisterCurrentToken(String userId) async {
    try {
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(vapidKey: vapidKey.contains("YOUR_VAPID") ? null : vapidKey);
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        final tokenDocId = token.hashCode.toString();
        await _firestore.collection('users').doc(userId).collection('fcm_tokens').doc(tokenDocId).delete();
        debugPrint('[FCMService] FCM Token successfully deleted from Firestore.');
      }
    } catch (e) {
      debugPrint('[FCMService] Error deleting FCM token from Firestore: $e');
    }
  }

  // ─── Foreground & Interactive Handlers ─────────────────────────────────────

  void _setupForegroundMessageListener() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCMService] Foreground message received: ${message.messageId}');

      final String? conversationId = message.data['conversationId'];
      final String notificationTitle = message.notification?.title ?? 'New Message';
      final String notificationBody = message.notification?.body ?? '';

      if (conversationId != null) {
        // If the user is currently viewing this conversation, do not show a notification banner
        if (_isUserViewingConversation(conversationId)) {
          debugPrint('[FCMService] User is already inside chat $conversationId, suppressing banner.');
          return;
        }

        // Show a premium GetX in-app notification banner
        Get.snackbar(
          notificationTitle,
          notificationBody,
          titleText: Text(
            notificationTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9), fontSize: 14),
          ),
          messageText: Text(
            notificationBody,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          backgroundColor: const Color(0xFF151E2E),
          borderColor: const Color(0xFF1E2D42),
          borderWidth: 0.5,
          borderRadius: 16,
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent, size: 24),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () {
              Get.back(); // Dismiss snackbar
              Get.toNamed('/chat', arguments: conversationId);
            },
            child: const Text(
              'VIEW',
              style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700),
            ),
          ),
          onTap: (_) {
            Get.toNamed('/chat', arguments: conversationId);
          },
        );
      }
    });
  }

  void _setupNotificationClickListeners() {
    // When the app is in the background but active in a tab, and a push notification is clicked
    _clickSubscription?.cancel();
    _clickSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCMService] Background message clicked and opened app: ${message.messageId}');
      _handleNotificationPayloadNavigation(message.data);
    });
  }

  /// Listens for window postMessage communication from the Service Worker (firebase-messaging-sw.js)
  void _setupServiceWorkerMessageListener() {
    _windowMessageSubscription?.cancel();
    _windowMessageSubscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is Map && data['type'] == 'NAVIGATE_TO_CONVERSATION') {
        final conversationId = data['conversationId'];
        debugPrint('[FCMService] Received SW postMessage navigate to conversation: $conversationId');
        if (conversationId != null) {
          Get.toNamed('/chat', arguments: conversationId);
        }
      }
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  bool _isUserViewingConversation(String conversationId) {
    try {
      if (Get.currentRoute == '/chat') {
        final chatController = Get.find<ChatController>();
        return chatController.conversationId == conversationId;
      }
    } catch (_) {}
    return false;
  }

  void _handleNotificationPayloadNavigation(Map<String, dynamic> data) {
    final String? conversationId = data['conversationId'];
    if (conversationId != null && conversationId.isNotEmpty) {
      Get.toNamed('/chat', arguments: conversationId);
    }
  }

  /// Processes URL arguments on app launch to route users when opening background notifications in a new tab
  void checkLaunchUrlArguments() {
    if (!kIsWeb) return;

    try {
      final uri = Uri.parse(html.window.location.href);
      // Support both query param (?id=abc) and fragment-based routes (/#/chat?id=abc)
      String? conversationId = uri.queryParameters['id'];

      if (conversationId == null && uri.fragment.contains('id=')) {
        final queryPart = uri.fragment.split('?').last;
        final params = Uri.splitQueryString(queryPart);
        conversationId = params['id'];
      }

      if (conversationId != null && conversationId.isNotEmpty) {
        debugPrint('[FCMService] Direct launching chat via deep link: $conversationId');
        // Route after Get is ready using standard post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed('/chat', arguments: conversationId);
        });
      }
    } catch (e) {
      debugPrint('[FCMService] Error checking launching URL: $e');
    }
  }
}
