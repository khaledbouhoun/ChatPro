// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String?,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      status: fields[4] as String,
      createdAt: fields[5] as DateTime,
      localId: fields[6] as String?,
      replyToId: fields[7] as String?,
      replyToContent: fields[8] as String?,
      replyToSenderId: fields[9] as String?,
      fileUrl: fields[10] as String?,
      fileType: fields[11] as String?,
      reactions: (fields[12] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.localId)
      ..writeByte(7)
      ..write(obj.replyToId)
      ..writeByte(8)
      ..write(obj.replyToContent)
      ..writeByte(9)
      ..write(obj.replyToSenderId)
      ..writeByte(10)
      ..write(obj.fileUrl)
      ..writeByte(11)
      ..write(obj.fileType)
      ..writeByte(12)
      ..write(obj.reactions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
