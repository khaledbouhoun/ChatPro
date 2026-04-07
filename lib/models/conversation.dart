import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'participant.dart';

part 'conversation.g.dart';

@HiveType(typeId: 1)
class Conversation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? otherUserName;

  @HiveField(2)
  final String? lastMessage;

  @HiveField(3)
  final DateTime? lastMessageTime;

  @HiveField(4)
  final int unreadCount;

  @HiveField(5)
  final Map<String, Participant> participants; // Changed from List to Map

  Conversation({
    required this.id,
    this.otherUserName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.participants,
  });

  // -------------------- copyWith --------------------
  Conversation copyWith({
    String? id,
    String? otherUserName,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    Map<String, Participant>? participants,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserName: otherUserName ?? this.otherUserName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      participants: participants ?? this.participants,
    );
  }

  // -------------------- Firestore --------------------
  factory Conversation.fromFirestore(Map<String, dynamic> json, String docId, String currentUserId) {
    // Convert participants map into Map<String, Participant>
    final Map<String, dynamic> participantsData = json['participants'] as Map<String, dynamic>? ?? {};

    final Map<String, Participant> participantsMap = {};
    participantsData.forEach((userId, data) {
      participantsMap[userId] = Participant(
        id: userId,
        name: data['name'] ?? '',
        unreadCount: data['unread_count'] ?? 0,
      );
    });

    // Detect current user participant
    final currentUserPart = participantsMap[currentUserId] ?? Participant(id: currentUserId, name: 'You');

    // Detect other user participant
    final otherPart = participantsMap.values.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => Participant(id: '', name: 'Unknown'),
    );

    return Conversation(
      id: docId,
      otherUserName: otherPart.name,
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] != null ? (json['last_message_time'] as Timestamp).toDate() : null,
      unreadCount: currentUserPart.unreadCount,
      participants: participantsMap,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      otherUserName: json['other_user']?['name'] ?? 'Unknown',
      lastMessage: json['last_message']?['content'],
      lastMessageTime: json['last_message'] != null ? DateTime.parse(json['last_message']['created_at']) : null,
      unreadCount: json['unread_count'] ?? 0,
      participants: {}, // Default empty map
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants.map((key, value) => MapEntry(key, value.toFirestore())),
      'participants_ids': participants.keys.toList(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
    };
  }
}
