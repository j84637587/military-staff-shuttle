import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/shuttle_record.dart';
import '../models/student_ride.dart';
import '../services/storage_service.dart';

/// 應用程式主要狀態管理
class AppProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Station> _stations = [];
  List<ShuttleRecord> _records = [];
  bool _isLoading = false;

  List<Station> get stations => _stations;
  List<ShuttleRecord> get records => _records;
  bool get isLoading => _isLoading;

  /// 初始化資料
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _stations = await _storageService.loadStations();
    _records = await _storageService.loadRecords();

    _isLoading = false;
    notifyListeners();
  }

  // ========== 站點管理 ==========

  /// 新增站點
  Future<void> addStation(Station station) async {
    _stations.add(station);
    await _storageService.saveStations(_stations);
    notifyListeners();
  }

  /// 更新站點
  Future<void> updateStation(String id, Station updatedStation) async {
    final index = _stations.indexWhere((s) => s.id == id);
    if (index != -1) {
      _stations[index] = updatedStation;
      await _storageService.saveStations(_stations);
      notifyListeners();
    }
  }

  /// 刪除站點
  Future<void> deleteStation(String id) async {
    _stations.removeWhere((s) => s.id == id);
    await _storageService.saveStations(_stations);
    notifyListeners();
  }

  // ========== 專車記錄管理 ==========

  /// 新增專車記錄
  Future<void> addRecord(ShuttleRecord record) async {
    _records.add(record);
    // 依日期排序（最新的在前）
    _records.sort((a, b) => b.date.compareTo(a.date));
    await _storageService.saveRecords(_records);
    notifyListeners();
  }

  /// 更新專車記錄
  Future<void> updateRecord(String id, ShuttleRecord updatedRecord) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index] = updatedRecord;
      _records.sort((a, b) => b.date.compareTo(a.date));
      await _storageService.saveRecords(_records);
      notifyListeners();
    }
  }

  /// 刪除專車記錄
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _storageService.saveRecords(_records);
    notifyListeners();
  }

  /// 複製專車記錄（建立副本供編輯）
  ShuttleRecord duplicateRecord(ShuttleRecord record) {
    return record.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
  }

  // ========== 統計計算 ==========

  /// 計算記錄的統計資料
  Map<String, dynamic> calculateStatistics(ShuttleRecord record) {
    final stationStats = <String, Map<String, dynamic>>{};
    int totalStudents = 0;
    int totalCost = 0;

    // 依站點分組統計
    for (final ride in record.rides) {
      final station = _stations.firstWhere(
        (s) => s.id == ride.stationId,
        orElse: () => Station(id: ride.stationId, name: '未知站點', price: 0),
      );

      if (!stationStats.containsKey(station.id)) {
        stationStats[station.id] = {
          'station': station,
          'roundTrip': <String>[],
          'oneWay': <String>[],
        };
      }

      final stats = stationStats[station.id]!;
      if (ride.rideType == RideType.roundTrip) {
        (stats['roundTrip'] as List<String>).add(ride.studentNumber);
      } else {
        (stats['oneWay'] as List<String>).add(ride.studentNumber);
      }
    }

    // 計算每個站點的人數和費用
    final stationResults = <Map<String, dynamic>>[];
    for (final entry in stationStats.entries) {
      final station = entry.value['station'] as Station;
      final roundTripStudents = entry.value['roundTrip'] as List<String>;
      final oneWayStudents = entry.value['oneWay'] as List<String>;

      final roundTripCount = roundTripStudents.length;
      final oneWayCount = oneWayStudents.length;
      final totalCount = roundTripCount + oneWayCount;

      final cost =
          (roundTripCount * station.roundTripPrice) +
          (oneWayCount * station.price);

      stationResults.add({
        'station': station,
        'roundTripStudents': roundTripStudents,
        'oneWayStudents': oneWayStudents,
        'roundTripCount': roundTripCount,
        'oneWayCount': oneWayCount,
        'totalCount': totalCount,
        'cost': cost,
      });

      totalStudents += totalCount;
      totalCost += cost;
    }

    // 依站點名稱排序
    stationResults.sort(
      (a, b) => (a['station'] as Station).name.compareTo(
        (b['station'] as Station).name,
      ),
    );

    return {
      'stationStats': stationResults,
      'totalStudents': totalStudents,
      'totalCost': totalCost,
    };
  }
}
