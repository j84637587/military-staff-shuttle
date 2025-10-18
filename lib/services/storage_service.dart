import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';
import '../models/shuttle_record.dart';

/// 本地資料儲存服務
class StorageService {
  static const String _stationsKey = 'stations';
  static const String _recordsKey = 'shuttle_records';

  // 儲存站點列表
  Future<void> saveStations(List<Station> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final stationsJson = stations.map((s) => s.toJson()).toList();
    await prefs.setString(_stationsKey, jsonEncode(stationsJson));
  }

  // 讀取站點列表
  Future<List<Station>> loadStations() async {
    final prefs = await SharedPreferences.getInstance();
    final stationsString = prefs.getString(_stationsKey);
    if (stationsString == null) {
      return _getDefaultStations();
    }

    final List<dynamic> stationsJson = jsonDecode(stationsString);
    return stationsJson
        .map((json) => Station.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 儲存專車記錄列表
  Future<void> saveRecords(List<ShuttleRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records.map((r) => r.toJson()).toList();
    await prefs.setString(_recordsKey, jsonEncode(recordsJson));
  }

  // 讀取專車記錄列表
  Future<List<ShuttleRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsString = prefs.getString(_recordsKey);
    if (recordsString == null) {
      return [];
    }

    final List<dynamic> recordsJson = jsonDecode(recordsString);
    return recordsJson
        .map((json) => ShuttleRecord.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // 預設站點（根據您的需求）
  List<Station> _getDefaultStations() {
    return [
      Station(id: '1', name: '新竹', price: 400),
      Station(id: '2', name: '苗栗', price: 380),
    ];
  }
}
