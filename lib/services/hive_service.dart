import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/participant.dart';
import '../models/user_model.dart';

class HiveService extends GetxService {
  late final Box<Message> _messageBox;
  late final Box<Conversation> _conversationBox;
  late final Box<UserModel> _userBox;
  late final Box<String> _sessionBox;

  static const _kMessages = 'messages';
  static const _kConversations = 'conversations';
  static const _kUser = 'user_profile';
  static const _kSession = 'user_session';
  static const _kUserId = 'userId';

  Future<HiveService> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    _messageBox = await Hive.openBox<Message>(_kMessages);
    _conversationBox = await Hive.openBox<Conversation>(_kConversations);
    _userBox = await Hive.openBox<UserModel>(_kUser);
    _sessionBox = await Hive.openBox<String>(_kSession);
    return this;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MessageAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ConversationAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ParticipantAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(UserModelAdapter());
  }

  // ─── Session ───────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    await Future.wait([_userBox.put(_kUserId, user), _sessionBox.put(_kUserId, user.id)]);
  }

  UserModel? getUser() => _userBox.get(_kUserId);
  String? getCurrentUserId() => _sessionBox.get(_kUserId);

  Future<void> clearAuthData() async {
    await Future.wait([_userBox.delete(_kUserId), _sessionBox.delete(_kUserId)]);
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  /// Saves or overwrites a message.
  /// Key priority: Firestore [Message.id] > [Message.localId].
  Future<void> saveMessage(Message message) async {
    final key = message.id ?? message.localId;
    if (key == null || key.isEmpty) {
      assert(false, 'saveMessage: message has neither id nor localId');
      return;
    }
    await _messageBox.put(key, message);
  }

  /// Returns ALL messages across every conversation.
  /// Used by [MessageQueueService] to find unsent messages globally.
  List<Message> getAllMessages() => _messageBox.values.toList();

  /// Returns messages for one conversation, sorted oldest-first.
  List<Message> getMessages(String conversationId) {
    return _messageBox.values.where((m) => m.conversationId == conversationId).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Deletes the message stored under [key]. No-op if key is absent.
  Future<void> deleteMessage(String key) async {
    if (_messageBox.containsKey(key)) {
      await _messageBox.delete(key);
    }
  }

  /// Bulk-deletes all messages belonging to [conversationId].
  Future<void> deleteMessagesForConversation(String conversationId) async {
    final keys = _messageBox.keys.where((k) {
      return _messageBox.get(k)?.conversationId == conversationId;
    }).toList();
    if (keys.isNotEmpty) await _messageBox.deleteAll(keys);
  }

  /// Updates only the status field without rewriting the full message.
  Future<void> updateMessageStatus(String key, String status) async {
    final existing = _messageBox.get(key);
    if (existing == null) return;
    await _messageBox.put(key, existing.copyWith(status: status));
  }

  // ─── Conversations ─────────────────────────────────────────────────────────

  Future<void> saveConversation(Conversation conv) async {
    await _conversationBox.put(conv.id, conv);
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final map = {for (final c in conversations) c.id: c};
    await _conversationBox.putAll(map);
  }

  Conversation? getConversation(String conversationId) => _conversationBox.get(conversationId);

  List<Conversation> getConversations(String currentUserId) {
    return _conversationBox.values.where((c) => c.participants.containsKey(currentUserId)).toList()
      ..sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime(0);
        final bTime = b.lastMessageTime ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
  }

  Future<void> deleteConversation(String id) async {
    await Future.wait([_conversationBox.delete(id), deleteMessagesForConversation(id)]);
  }

  // ─── Maintenance ───────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await Future.wait([_messageBox.clear(), _conversationBox.clear(), _userBox.clear(), _sessionBox.clear()]);
  }

  int get messageCount => _messageBox.length;
  int get conversationCount => _conversationBox.length;
}
