import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../services/hive_service.dart';

/// ChatController manages the full lifecycle of a single conversation screen.
class ChatController extends GetxController {
  // ─── Dependencies ──────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveService _hiveService = Get.find<HiveService>();

  // ─── Identity ──────────────────────────────────────────────────────────────
  final String conversationId;
  final String currentUserId;

  // ─── Observable state ──────────────────────────────────────────────────────
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  /// Whether the other participant is currently typing.
  final RxBool isOtherTyping = false.obs;

  final RxBool hasTextToSend = false.obs;

  /// Whether the other participant is online.
  final RxBool isOtherOnline = false.obs;

  /// Display name of the other participant (loaded from conversation).
  final RxString otherUserName = ''.obs;

  // ─── Search ────────────────────────────────────────────────────────────────
  final RxString searchQuery = ''.obs;

  List<Message> get filteredMessages {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return messages;
    return messages.where((m) => m.content.toLowerCase().contains(q)).toList();
  }

  // ─── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // ─── Internal ──────────────────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<DocumentSnapshot>? _presenceSubscription;
  StreamSubscription<DocumentSnapshot>? _typingSubscription;
  DocumentSnapshot? _oldestCursor;
  bool _isAtBottom = true;
  Timer? _typingDebounce;
  bool _isCurrentlyTyping = false;

  static const int _pageSize = 20;

  // ─── Constructor ───────────────────────────────────────────────────────────
  ChatController({String? id})
      : conversationId = (id ?? (Get.arguments as String?)) ?? '',
        currentUserId = Get.find<HiveService>().getCurrentUserId() ?? '';

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _initScrollListener();
    _initTypingListener();
    _bootstrap();
  }

  @override
  void onClose() {
    _chatSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingDebounce?.cancel();
    _clearTypingStatus();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ─── Init ──────────────────────────────────────────────────────────────────
  void _initScrollListener() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      _isAtBottom = pos.maxScrollExtent - pos.pixels < 80;
      if (pos.pixels <= pos.minScrollExtent + 120) loadMore();
    });
  }

  void _initTypingListener() {
    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;
      if (hasText && !_isCurrentlyTyping) {
        _isCurrentlyTyping = true;
        _setTypingStatus(true);
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (_isCurrentlyTyping) {
          _isCurrentlyTyping = false;
          _setTypingStatus(false);
        }
      });
    });
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    await _loadOtherUserInfo();
    await _loadAndRenderLocal();
    isLoading.value = false;
    _setupFirestoreStream();
    _setupPresenceStream();
    _setupTypingStream();
    _markAsRead();
  }

  // ─── Other user info ───────────────────────────────────────────────────────
  Future<void> _loadOtherUserInfo() async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final participants = Map<String, dynamic>.from(data['participants'] ?? {});
      String? otherUserId;
      for (final key in participants.keys) {
        if (key != currentUserId) {
          otherUserId = key;
          otherUserName.value = participants[key]['name'] ?? 'Unknown';
          break;
        }
      }
      if (otherUserId != null) {
        _setupPresenceStreamForUser(otherUserId);
        _setupTypingStreamForUser(otherUserId);
      }
    } catch (e) {
      debugPrint('[Chat] _loadOtherUserInfo error: $e');
    }
  }

  // ─── Presence / Online ─────────────────────────────────────────────────────
  void _setupPresenceStream() {
    // Handled in _loadOtherUserInfo after we know the other user's ID
  }

  void _setupPresenceStreamForUser(String userId) {
    _presenceSubscription = _firestore.collection('users').doc(userId).snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      // Prefer explicit flag
      if (data.containsKey('is_online')) {
        isOtherOnline.value = data['is_online'] == true;
        return;
      }
      final lastSeen = data['last_seen'] as Timestamp?;
      if (lastSeen != null) {
        final diff = DateTime.now().difference(lastSeen.toDate());
        isOtherOnline.value = diff.inMinutes < 2;
      }
    }, onError: (e) => debugPrint('[Chat] Presence error: $e'));
  }

  // ─── Typing indicators ─────────────────────────────────────────────────────
  void _setupTypingStream() {
    // Handled in _loadOtherUserInfo
  }

  void _setupTypingStreamForUser(String userId) {
    _typingSubscription = _firestore.collection('conversations').doc(conversationId).snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final typing = Map<String, dynamic>.from(data['typing'] ?? {});
      isOtherTyping.value = typing[userId] == true;
    }, onError: (e) => debugPrint('[Chat] Typing stream error: $e'));
  }

  Future<void> _setTypingStatus(bool isTyping) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).set({
        'typing': {currentUserId: isTyping},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _clearTypingStatus() async {
    try {
      await _firestore.collection('conversations').doc(conversationId).set({
        'typing': {currentUserId: false},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ─── Local cache ───────────────────────────────────────────────────────────
  Future<void> _loadAndRenderLocal({bool scrollToBottom = true}) async {
    final local = _hiveService.getMessages(conversationId);
    if (_listsDiffer(messages, local)) {
      messages.assignAll(local);
    }
    if (scrollToBottom && _isAtBottom) _scrollToBottom();
  }

  bool _listsDiffer(List<Message> a, List<Message> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].id ?? a[i].localId) != (b[i].id ?? b[i].localId) ||
          a[i].status != b[i].status ||
          !_mapsEqual(a[i].reactions, b[i].reactions)) {
        return true;
      }
    }
    return false;
  }

  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || b[k] != a[k]) return false;
    }
    return true;
  }

  // ─── Firestore stream ──────────────────────────────────────────────────────
  void _setupFirestoreStream() {
    _chatSubscription = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen(_onSnapshotReceived, onError: (e) => debugPrint('[Chat] Stream error: $e'));
  }

  Future<void> _onSnapshotReceived(QuerySnapshot snapshot) async {
    if (snapshot.docs.isNotEmpty && _oldestCursor == null) {
      _oldestCursor = snapshot.docs.last;
    }
    bool localDirty = false;
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final msg = Message.fromFirestore(data, change.doc.id);
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          // Reconcile: remove the pending local copy keyed by localId
          if (msg.localId != null) {
            await _hiveService.deleteMessage(msg.localId!);
          }
          await _hiveService.saveMessage(msg);
          localDirty = true;
          // If the other user sent a message while we're viewing, mark it read
          if (msg.senderId != currentUserId && msg.status != 'read') {
            _markSingleMessageRead(change.doc.id);
          }
          break;
        case DocumentChangeType.removed:
          await _hiveService.deleteMessage(change.doc.id);
          if (msg.localId != null) {
            await _hiveService.deleteMessage(msg.localId!);
          }
          localDirty = true;
          break;
      }
    }
    if (localDirty) await _loadAndRenderLocal();
  }

  /// Mark a single incoming message as read immediately (no batch delay).
  Future<void> _markSingleMessageRead(String messageId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).collection('messages').doc(messageId).update({'status': 'read'});
    } catch (_) {}
  }

  // ─── Pagination ────────────────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || _oldestCursor == null) return;
    isLoadingMore.value = true;
    final previousOffset = scrollController.hasClients ? scrollController.position.pixels : 0.0;
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('created_at', descending: true)
          .startAfterDocument(_oldestCursor!)
          .limit(_pageSize)
          .get();
      if (snapshot.docs.length < _pageSize) hasMore.value = false;
      if (snapshot.docs.isNotEmpty) {
        _oldestCursor = snapshot.docs.last;
        for (final doc in snapshot.docs) {
          final msg = Message.fromFirestore(doc.data(), doc.id);
          await _hiveService.saveMessage(msg);
        }
        await _loadAndRenderLocal(scrollToBottom: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(previousOffset);
          }
        });
      }
    } catch (e) {
      debugPrint('[Chat] loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── Sending ───────────────────────────────────────────────────────────────
  Future<void> sendCurrentMessage({Message? replyTo}) async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messageController.clear();
    _isCurrentlyTyping = false;
    _setTypingStatus(false);
    await sendMessage(text, replyTo: replyTo);
  }

  Future<void> sendMessage(String text, {String? existingLocalId, Message? replyTo}) async {
    final localId = existingLocalId ?? const Uuid().v4();
    final pending = Message(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: text,
      status: 'pending',
      createdAt: DateTime.now(),
      replyToId: replyTo?.id ?? replyTo?.localId,
      replyToContent: replyTo?.content,
      replyToSenderId: replyTo?.senderId,
    );
    await _hiveService.saveMessage(pending);
    await _loadAndRenderLocal();
    try {
      final convRef = _firestore.collection('conversations').doc(conversationId);
      final msgRef = convRef.collection('messages').doc();
      await _firestore.runTransaction((tx) async {
        final convSnap = await tx.get(convRef);
        if (!convSnap.exists) {
          throw Exception('Conversation $conversationId does not exist.');
        }
        final data = convSnap.data() as Map<String, dynamic>;
        final participants = Map<String, dynamic>.from(data['participants'] ?? {});
        final updates = <String, dynamic>{'last_message': text, 'last_message_time': FieldValue.serverTimestamp()};
        for (final userId in participants.keys) {
          if (userId != currentUserId) {
            updates['participants.$userId.unread_count'] = FieldValue.increment(1);
          }
        }
        tx.set(msgRef, {...pending.toFirestore(), 'status': 'sent', 'local_id': localId});
        tx.update(convRef, updates);
      });
    } catch (e) {
      debugPrint('[Chat] sendMessage error: $e');
      await _hiveService.saveMessage(pending.copyWith(status: 'failed'));
      await _loadAndRenderLocal(scrollToBottom: false);
    }
  }

  /// Send a message with a file/image/audio attachment.
  Future<void> sendFileMessage(String content, String fileUrl, String fileType) async {
    final localId = const Uuid().v4();
    final pending = Message(
      localId: localId,
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      status: 'pending',
      createdAt: DateTime.now(),
      fileUrl: fileUrl,
      fileType: fileType,
    );
    await _hiveService.saveMessage(pending);
    await _loadAndRenderLocal();
    try {
      final convRef = _firestore.collection('conversations').doc(conversationId);
      final msgRef = convRef.collection('messages').doc();
      await _firestore.runTransaction((tx) async {
        final convSnap = await tx.get(convRef);
        if (!convSnap.exists) return;
        final data = convSnap.data() as Map<String, dynamic>;
        final participants = Map<String, dynamic>.from(data['participants'] ?? {});
        final updates = <String, dynamic>{
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
        };
        for (final userId in participants.keys) {
          if (userId != currentUserId) {
            updates['participants.$userId.unread_count'] = FieldValue.increment(1);
          }
        }
        tx.set(msgRef, {
          ...pending.toFirestore(),
          'status': 'sent',
          'local_id': localId,
          'file_url': fileUrl,
          'file_type': fileType,
        });
        tx.update(convRef, updates);
      });
    } catch (e) {
      debugPrint('[Chat] sendFileMessage error: $e');
      await _hiveService.saveMessage(pending.copyWith(status: 'failed'));
      await _loadAndRenderLocal(scrollToBottom: false);
    }
  }

  /// Save or toggle a reaction on a message in Firestore.
  /// If the current user already set the same emoji, it removes it.
  Future<void> saveReaction(String messageId, String emoji) async {
    try {
      final docRef = _firestore.collection('conversations').doc(conversationId).collection('messages').doc(messageId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() as Map<String, dynamic>;
        final current = Map<String, dynamic>.from(data['reactions'] ?? {});

        if (current[currentUserId] == emoji) {
          // Toggle off
          current.remove(currentUserId);
        } else {
          current[currentUserId] = emoji;
        }
        tx.update(docRef, {'reactions': current});
      });
    } catch (e) {
      debugPrint('[Chat] saveReaction error: $e');
    }
  }

  Future<void> retryMessage(Message failed) async {
    if (failed.localId == null) return;
    if (failed.hasFile && failed.fileUrl != null) {
      await sendFileMessage(failed.content, failed.fileUrl!, failed.fileType ?? 'document');
    } else {
      await sendMessage(failed.content, existingLocalId: failed.localId);
    }
  }

  Future<void> discardFailedMessage(Message msg) async {
    final key = msg.localId ?? msg.id;
    if (key != null) {
      await _hiveService.deleteMessage(key);
      await _loadAndRenderLocal(scrollToBottom: false);
    }
  }

  // ─── Read receipts ─────────────────────────────────────────────────────────

  /// Bulk mark all unread messages from the other user as 'read'.
  Future<void> _markAsRead() async {
    try {
      // Reset unread counter in conversation doc
      await _firestore.runTransaction((tx) async {
        final convRef = _firestore.collection('conversations').doc(conversationId);
        final snap = await tx.get(convRef);
        if (!snap.exists) return;
        final data = snap.data() as Map<String, dynamic>;
        final pMap = Map<String, dynamic>.from(data['participants'] ?? {});
        if (pMap.containsKey(currentUserId)) {
          final pData = Map<String, dynamic>.from(pMap[currentUserId] as Map);
          if ((pData['unread_count'] ?? 0) > 0) {
            tx.update(convRef, {'participants.$currentUserId.unread_count': 0});
          }
        }
      });

      // Update message statuses in Firestore so the sender sees double-blue tick
      // Fetch unread messages without isNotEqualTo to avoid composite index requirement
      final sentQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('status', isEqualTo: 'sent')
          .get();

      final deliveredQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('status', isEqualTo: 'delivered')
          .get();

      // Filter to only messages not from current user
      final allDocs = [
        ...sentQuery.docs.where((doc) => doc['sender_id'] != currentUserId),
        ...deliveredQuery.docs.where((doc) => doc['sender_id'] != currentUserId),
      ].toList();
      
      if (allDocs.isNotEmpty) {
        const batchLimit = 499;
        for (var i = 0; i < allDocs.length; i += batchLimit) {
          final chunk = allDocs.skip(i).take(batchLimit);
          final batch = _firestore.batch();
          for (final doc in chunk) {
            batch.update(doc.reference, {'status': 'read'});
          }
          await batch.commit();
        }
      }

      // Reflect locally
      final localMsgs = _hiveService.getMessages(conversationId);
      bool dirty = false;
      for (final m in localMsgs) {
        if (m.senderId != currentUserId && m.status != 'read' && m.id != null) {
          await _hiveService.saveMessage(m.copyWith(status: 'read'));
          dirty = true;
        }
      }
      if (dirty) await _loadAndRenderLocal(scrollToBottom: false);
    } catch (e) {
      debugPrint('[Chat] markAsRead error: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void scrollToBottom() => _scrollToBottom();
}
