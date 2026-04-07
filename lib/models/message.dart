import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String conversationId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String status; // 'pending', 'sent', 'delivered', 'read', 'failed'

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? localId;

  // ─── Reply fields ──────────────────────────────────────────────────────────
  @HiveField(7)
  final String? replyToId;

  @HiveField(8)
  final String? replyToContent;

  @HiveField(9)
  final String? replyToSenderId;

  // ─── Attachment fields ─────────────────────────────────────────────────────
  @HiveField(10)
  final String? fileUrl;

  /// 'image' | 'audio' | 'video' | 'document'
  @HiveField(11)
  final String? fileType;

  // ─── Reactions ─────────────────────────────────────────────────────────────
  /// Map of userId → emoji
  @HiveField(12)
  final Map<String, String> reactions;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.status,
    required this.createdAt,
    this.localId,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.fileUrl,
    this.fileType,
    this.reactions = const {},
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? status,
    DateTime? createdAt,
    String? localId,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? fileUrl,
    String? fileType,
    Map<String, String>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      localId: localId ?? this.localId,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromFirestore(Map<String, dynamic> json, String docId) {
    // Parse reactions map
    final reactionsRaw = Map<String, dynamic>.from(json['reactions'] as Map? ?? {});
    final reactions = reactionsRaw.map((k, v) => MapEntry(k, v.toString()));

    return Message(
      id: docId,
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? 'sent',
      createdAt: json['created_at'] != null ? (json['created_at'] as Timestamp).toDate() : DateTime.now(),
      localId: json['local_id'],
      replyToId: json['reply_to_id'],
      replyToContent: json['reply_to_content'],
      replyToSenderId: json['reply_to_sender_id'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      reactions: reactions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'local_id': localId,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToContent != null) 'reply_to_content': replyToContent,
      if (replyToSenderId != null) 'reply_to_sender_id': replyToSenderId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
      if (reactions.isNotEmpty) 'reactions': reactions,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      content: json['content'] ?? '',
      status: json['status'] ?? 'sent',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      localId: json['local_id'],
      replyToId: json['reply_to_id'],
      replyToContent: json['reply_to_content'],
      replyToSenderId: json['reply_to_sender_id'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'local_id': localId,
      'reply_to_id': replyToId,
      'reply_to_content': replyToContent,
      'reply_to_sender_id': replyToSenderId,
      'file_url': fileUrl,
      'file_type': fileType,
      'reactions': reactions,
    };
  }

  bool get hasReply => replyToId != null || replyToContent != null;
  bool get hasFile => fileUrl != null;
  bool get isImage => fileType == 'image';
  bool get isAudio => fileType == 'audio';
  bool get isVideo => fileType == 'video';
  bool get isDocument => fileType == 'document';
}
