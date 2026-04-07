import 'dart:math';

import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 3)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final String chatCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.chatCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['uid'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      chatCode: json['chat_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'chat_code': chatCode,
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> json, String docId) {
    return UserModel(
      id: docId,
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      chatCode: json['chat_code'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'chat_code': chatCode,
    };
  }

  UserModel copyWith({String? id, String? name, String? email, String? photoUrl, String? chatCode}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      chatCode: chatCode ?? this.chatCode,
    );
  }

  String generateChatCode(String name) {
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    String prefix = name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
    return "$prefix#$random";
  }
}
