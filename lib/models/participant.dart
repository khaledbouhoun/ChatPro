import 'package:hive/hive.dart';

part 'participant.g.dart';

@HiveType(typeId: 2)
class Participant {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  int unreadCount;

  Participant({required this.id, required this.name, this.unreadCount = 0});

  // -------------------- copyWith --------------------
  Participant copyWith({String? id, String? name, int? unreadCount}) {
    return Participant(id: id ?? this.id, name: name ?? this.name, unreadCount: unreadCount ?? this.unreadCount);
  }

  // -------------------- Firestore --------------------
  factory Participant.fromFirestore(Map<String, dynamic> json) {
    return Participant(id: json['id'] ?? '', name: json['name'] ?? 'Unknown', unreadCount: json['unread_count'] ?? 0);
  }

  Map<String, dynamic> toFirestore() {
    return {'id': id, 'name': name, 'unread_count': unreadCount};
  }
}
