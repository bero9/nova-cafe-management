// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogItemAdapter extends TypeAdapter<DailyLogItem> {
  @override
  final int typeId = 2;

  @override
  DailyLogItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLogItem(
      userName: fields[0] as String,
      tableNumber: fields[1] as String,
      totalBill: fields[2] as double,
      purchasesTotal: fields[3] as double,
      timeCost: fields[4] as double,
      date: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.tableNumber)
      ..writeByte(2)
      ..write(obj.totalBill)
      ..writeByte(3)
      ..write(obj.purchasesTotal)
      ..writeByte(4)
      ..write(obj.timeCost)
      ..writeByte(5)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriberAdapter extends TypeAdapter<Subscriber> {
  @override
  final int typeId = 3;

  @override
  Subscriber read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscriber(
      id: fields[0] as String,
      name: fields[1] as String,
      joinDate: fields[2] as DateTime,
      type: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Subscriber obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.joinDate)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
