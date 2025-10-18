/// 學員搭乘類型
enum RideType {
  roundTrip, // 來回
  leaveBase, // 離營（去程）
  returnBase, // 回營（返程）
}

/// 學員搭乘資料
class StudentRide {
  final String studentNumber; // 學號（例如：001, 023）
  final String stationId; // 站點ID
  final RideType rideType; // 搭乘類型

  StudentRide({
    required this.studentNumber,
    required this.stationId,
    required this.rideType,
  });

  factory StudentRide.fromJson(Map<String, dynamic> json) {
    return StudentRide(
      studentNumber: json['studentNumber'] as String,
      stationId: json['stationId'] as String,
      rideType: RideType.values[json['rideType'] as int],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentNumber': studentNumber,
      'stationId': stationId,
      'rideType': rideType.index,
    };
  }

  StudentRide copyWith({
    String? studentNumber,
    String? stationId,
    RideType? rideType,
  }) {
    return StudentRide(
      studentNumber: studentNumber ?? this.studentNumber,
      stationId: stationId ?? this.stationId,
      rideType: rideType ?? this.rideType,
    );
  }
}
