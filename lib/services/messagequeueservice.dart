import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/message.dart';
import '../services/hive_service.dart';

/// MessageQueueService watches connectivity and automatically flushes any
/// messages that are stored locally as 'pending' or 'failed' back to Firestore
/// the moment the device comes back online.
///
/// Lifecycle:
///   1. App starts  → scan Hive for leftover pending/failed messages and retry.
///   2. Goes offline → outbound sends fail silently; ChatController stores them
///      as 'pending'/'failed' in Hive.
///   3. Back online  → connectivity stream fires → flush queue → Firestore
///      receives messages → stream reconciles local copies → UI updates.
///
/// Register in main.dart:
///   await Get.putAsync(() => MessageQueueService().init());
///   (must be registered AFTER HiveService)
class MessageQueueService extends GetxService {
  final HiveService _hive = Get.find<HiveService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Exposed so UI can show a "syncing…" indicator if desired.
  final RxBool isFlushing = false.obs;

  /// Total unsent messages across all conversations.
  final RxInt pendingCount = 0.obs;

  // Debounce: avoid hammering Firestore if connectivity flaps rapidly.
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(seconds: 2);

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<MessageQueueService> init() async {
    _updatePendingCount();
    _listenToConnectivity();
    // On cold start, attempt flush immediately (device may already be online).
    await flushQueue();
    return this;
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ─── Connectivity watcher ──────────────────────────────────────────────────

  void _listenToConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        // Debounce: wait a moment for the connection to actually stabilize.
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_debounceDuration, () async {
          debugPrint('[Queue] Connection restored — flushing queue…');
          await flushQueue();
        });
      }
    });
  }

  // ─── Queue flush ──────────────────────────────────────────────────────────

  /// Scans Hive for all pending/failed messages across every conversation and
  /// retries them in chronological order (oldest first).
  Future<void> flushQueue() async {
    if (isFlushing.value) return; // already running

    final unsent = _getUnsentMessages();
    if (unsent.isEmpty) return;

    isFlushing.value = true;
    debugPrint('[Queue] Flushing ${unsent.length} unsent message(s)…');

    try {
      // Group by conversationId so we can do per-conversation transactions.
      final grouped = <String, List<Message>>{};
      for (final msg in unsent) {
        grouped.putIfAbsent(msg.conversationId, () => []).add(msg);
      }

      for (final entry in grouped.entries) {
        await _flushConversation(entry.key, entry.value);
      }
    } finally {
      isFlushing.value = false;
      _updatePendingCount();
    }
  }

  /// Sends all unsent messages for a single conversation sequentially.
  /// Sequential (not parallel) to preserve message order.
  Future<void> _flushConversation(String conversationId, List<Message> msgs) async {
    for (final msg in msgs) {
      await _retrySend(msg);
    }
  }

  /// Retries a single message. On success the local copy status becomes 'sent'
  /// (and the Firestore stream will later update it to 'delivered'/'read').
  /// On failure the message stays as 'failed' for the next flush cycle.
  Future<void> _retrySend(Message msg) async {
    final localKey = msg.localId ?? msg.id;
    if (localKey == null) return;

    // Optimistically mark as 'pending' so the UI shows a spinner, not ✗.
    await _hive.saveMessage(msg.copyWith(status: 'pending'));

    try {
      final convRef = _firestore.collection('conversations').doc(msg.conversationId);
      final msgRef = convRef.collection('messages').doc(); // new Firestore ID

      await _firestore.runTransaction((tx) async {
        final convSnap = await tx.get(convRef);
        if (!convSnap.exists) {
          throw Exception('Conversation ${msg.conversationId} not found.');
        }

        final data = convSnap.data() as Map<String, dynamic>;
        final participants = Map<String, dynamic>.from(data['participants'] ?? {});

        final updates = <String, dynamic>{
          'last_message': msg.content,
          'last_message_time': FieldValue.serverTimestamp(),
        };

        final senderId = msg.senderId;
        for (final userId in participants.keys) {
          if (userId != senderId) {
            updates['participants.$userId.unread_count'] = FieldValue.increment(1);
          }
        }

        tx.set(msgRef, {
          ...msg.toFirestore(),
          'status': 'sent',
          // Keep local_id so the Firestore stream can reconcile and delete the
          // pending Hive copy.
          'local_id': localKey,
        });

        tx.update(convRef, updates);
      });

      debugPrint('[Queue] ✓ Sent queued message $localKey');
      // Hive cleanup is handled by the Firestore stream listener in
      // ChatController._onSnapshotReceived when DocumentChangeType.added fires.
    } catch (e) {
      debugPrint('[Queue] ✗ Failed to send $localKey: $e');
      // Put back as 'failed' so the UI shows the retry icon.
      await _hive.saveMessage(msg.copyWith(status: 'failed'));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Returns all pending/failed messages across every conversation, sorted
  /// oldest-first so order is preserved on re-send.
  List<Message> _getUnsentMessages() {
    return _hive.getAllMessages().where((m) => m.status == 'pending' || m.status == 'failed').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void _updatePendingCount() {
    pendingCount.value = _hive.getAllMessages().where((m) => m.status == 'pending' || m.status == 'failed').length;
  }
}
