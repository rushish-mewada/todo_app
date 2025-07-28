// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      title: fields[0] as String,
      description: fields[1] as String,
      emoji: fields[2] as String,
      date: fields[3] as String,
      time: fields[4] as String,
      priority: fields[5] as String,
      isCompleted: fields[6] as bool?,
      status: fields[7] as String?,
      firebaseId: fields[8] as String?,
      isDeleted: fields[9] as bool?,
      needsUpdate: fields[10] as bool?,
      type: fields[11] as String,
      content: fields[12] as String?,
      frequency: (fields[13] as List?)?.cast<String>(),
      streak: fields[14] as int?,
      lastCompletedDate: fields[15] as String?,
      mood: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.firebaseId)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.needsUpdate)
      ..writeByte(11)
      ..write(obj.type)
      ..writeByte(12)
      ..write(obj.content)
      ..writeByte(13)
      ..write(obj.frequency)
      ..writeByte(14)
      ..write(obj.streak)
      ..writeByte(15)
      ..write(obj.lastCompletedDate)
      ..writeByte(16)
      ..write(obj.mood);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
