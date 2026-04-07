import 'dart:async';
import 'dart:ui';
import 'package:chat_pro/models/participant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/conversation.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';

class ConversationListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService = Get.find<HiveService>();

  final RxList<Conversation> conversations = <Conversation>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription? _conversationsSubscription;

  // Set after login — injected via Get.arguments or set directly
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _currentUserId = _hiveService.getCurrentUserId();
    debugPrint('[ConvList] currentUserId = $_currentUserId');

    loadLocalConversations();

    if (_currentUserId != null) {
      setupFirestoreStream();
    } else {
      // userId not in Hive yet — wait for it (race condition after fresh login)
      Future.delayed(const Duration(milliseconds: 500), () {
        _currentUserId = _hiveService.getCurrentUserId();
        debugPrint('[ConvList] delayed userId = $_currentUserId');
        if (_currentUserId != null) {
          setupFirestoreStream();
        } else {
          debugPrint('[ConvList] ERROR: still no userId after delay');
          isLoading.value = false;
        }
      });
    }
  }

  @override
  void onClose() {
    _conversationsSubscription?.cancel();
    super.onClose();
  }

  // ─── Load from Hive ────────────────────────────────────────────────────────

  void loadLocalConversations() {
    final localConvs = _hiveService.getConversations(_currentUserId ?? '');
    debugPrint('[ConvList] Hive has ${localConvs.length} conversations');
    if (localConvs.isNotEmpty) {
      conversations.assignAll(localConvs);
    }
    isLoading.value = false;
  }

  // ─── Firestore stream ──────────────────────────────────────────────────────

  void setupFirestoreStream() {
    final userId = _currentUserId;
    if (userId == null) return;

    debugPrint('[ConvList] Starting Firestore stream for $userId');

    // First try to load from Firestore cache immediately (works offline)
    _loadFromCacheFirst(userId);

    _conversationsSubscription?.cancel();
    _conversationsSubscription = _firestore.collection('conversations').where('participants_ids', arrayContains: userId).snapshots().listen(
      (snapshot) async {
        debugPrint('[ConvList] Snapshot received: ${snapshot.docs.length} docs, '
            '${snapshot.docChanges.length} changes');

        for (final change in snapshot.docChanges) {
          final doc = change.doc;
          if (doc.data() == null) continue;

          if (change.type == DocumentChangeType.removed) {
            await _hiveService.deleteConversation(doc.id);
            continue;
          }

          final conv = Conversation.fromFirestore(doc.data() as Map<String, dynamic>, doc.id, userId);
          await _hiveService.saveConversation(conv);
        }

        loadLocalConversations();
      },
      onError: (error) {
        // Stream error — log it but don't crash
        debugPrint('[ConvList] Stream error: $error');
        // Still show whatever we have locally
        loadLocalConversations();
      },
    );
  }

  // ─── Cache-first load (works even when offline) ────────────────────────────

  Future<void> _loadFromCacheFirst(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .where('participants_ids', arrayContains: userId)
          .get(const GetOptions(source: Source.cache));

      if (snapshot.docs.isNotEmpty) {
        debugPrint('[ConvList] Loaded ${snapshot.docs.length} from cache');
        for (final doc in snapshot.docs) {
          final conv = Conversation.fromFirestore(doc.data(), doc.id, userId);
          await _hiveService.saveConversation(conv);
        }
        loadLocalConversations();
      }
    } catch (e) {
      // Cache miss is normal on first launch — ignore
      debugPrint('[ConvList] Cache miss (normal on first run): $e');
    }
  }

  // ─── Create conversation ───────────────────────────────────────────────────

  Future<void> createConversationByCode(String chatCode) async {
    final currentUserId = _currentUserId ?? _hiveService.getCurrentUserId();
    if (currentUserId == null) {
      Get.snackbar('Error', 'Not logged in', backgroundColor: const Color(0xFF151E2E), colorText: const Color(0xFFF1F5F9));
      return;
    }

    isLoading.value = true;

    try {
      final userQuery = await _firestore.collection('users').where('chat_code', isEqualTo: chatCode.trim().toUpperCase()).limit(1).get();

      if (userQuery.docs.isEmpty) {
        Get.snackbar('Not Found', 'No user with that chat code',
            backgroundColor: const Color(0xFF151E2E), colorText: const Color(0xFFF1F5F9));
        return;
      }

      final targetUser = UserModel.fromFirestore(userQuery.docs.first.data(), userQuery.docs.first.id);

      if (targetUser.id == currentUserId) {
        Get.snackbar('Oops', "You can't start a chat with yourself",
            backgroundColor: const Color(0xFF151E2E), colorText: const Color(0xFFF1F5F9));
        return;
      }

      // Check if conversation already exists locally first
      final existing = conversations.firstWhereOrNull((c) => c.participants.containsKey(targetUser.id));
      if (existing != null) {
        Get.toNamed('/chat', arguments: existing.id);
        return;
      }

      final currentUser = _hiveService.getUser();
      if (currentUser == null) return;

      final participants = {
        currentUserId: Participant(id: currentUserId, name: currentUser.name, unreadCount: 0),
        targetUser.id: Participant(id: targetUser.id, name: targetUser.name, unreadCount: 1),
      };

      final conversation = Conversation(
        id: '',
        otherUserName: targetUser.name,
        lastMessage: 'Start chatting ✨',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        participants: participants,
      );

      final docRef = await _firestore.collection('conversations').add(conversation.toFirestore());

      Get.toNamed('/chat', arguments: docRef.id);
    } catch (e) {
      debugPrint('[ConvList] createConversation error: $e');
      Get.snackbar('Error', 'Could not create conversation: $e',
          backgroundColor: const Color(0xFF151E2E), colorText: const Color(0xFFF1F5F9));
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Delete conversation ───────────────────────────────────────────────────

  Future<void> deleteConversation(String id) async {
    try {
      await _firestore.collection('conversations').doc(id).delete();
      await _hiveService.deleteConversation(id);
      conversations.removeWhere((c) => c.id == id);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete: $e', backgroundColor: const Color(0xFF151E2E), colorText: const Color(0xFFF1F5F9));
    }
  }

  // ─── Mark as read ──────────────────────────────────────────────────────────

  Future<void> markAsRead(String conversationId) async {
    final currentUserId = _currentUserId ?? _hiveService.getCurrentUserId();
    if (currentUserId == null) return;

    try {
      await _firestore.collection('conversations').doc(conversationId).update({'participants.$currentUserId.unread_count': 0});

      final conv = _hiveService.getConversation(conversationId);
      if (conv != null) {
        final updated = Map<String, Participant>.from(conv.participants);
        if (updated.containsKey(currentUserId)) {
          updated[currentUserId] = updated[currentUserId]!.copyWith(unreadCount: 0);
        }
        await _hiveService.saveConversation(conv.copyWith(participants: updated, unreadCount: 0));
      }
    } catch (e) {
      debugPrint('[ConvList] markAsRead error: $e');
    }
  }
}
