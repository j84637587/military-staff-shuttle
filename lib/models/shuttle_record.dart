import 'student_ride.dart';

/// 專車記錄
class ShuttleRecord {
  final String id;
  final DateTime date; // 日期
  final String className; // 班級名稱（例如：步二連）
  final int totalStudents; // 總學員數量
  final List<StudentRide> rides; // 所有學員搭乘資料
  final DateTime createdAt; // 建立時間

  ShuttleRecord({
    required this.id,
    required this.date,
    required this.className,
    required this.totalStudents,
    required this.rides,
    required this.createdAt,
  });

  factory ShuttleRecord.fromJson(Map<String, dynamic> json) {
    return ShuttleRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      className: json['className'] as String,
      totalStudents: json['totalStudents'] as int,
      rides: (json['rides'] as List)
          .map((r) => StudentRide.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'className': className,
      'totalStudents': totalStudents,
      'rides': rides.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ShuttleRecord copyWith({
    String? id,
    DateTime? date,
    String? className,
    int? totalStudents,
    List<StudentRide>? rides,
    DateTime? createdAt,
  }) {
    return ShuttleRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      className: className ?? this.className,
      totalStudents: totalStudents ?? this.totalStudents,
      rides: rides ?? this.rides,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
