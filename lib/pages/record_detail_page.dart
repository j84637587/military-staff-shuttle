import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/shuttle_record.dart';
import '../models/station.dart';
import 'create_record_page.dart';

/// 記錄詳細頁面
class RecordDetailPage extends StatelessWidget {
  final ShuttleRecord record;

  const RecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final stats = provider.calculateStatistics(record);
    final dateStr = DateFormat('yyyy/MM/dd').format(record.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('$dateStr ${record.className}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateRecordPage(existingRecord: record),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context, stats),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'duplicate') {
                _duplicateRecord(context, provider);
              } else if (value == 'delete') {
                _confirmDelete(context, provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.content_copy),
                    SizedBox(width: 8),
                    Text('複製記錄'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('刪除記錄', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本資訊
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dateStr ${record.className} 專車來回',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '班級學員總數: ${record.totalStudents} 員',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            // 各站點詳細資訊
            ...List.generate((stats['stationStats'] as List).length, (index) {
              final stationStat = (stats['stationStats'] as List)[index];
              return _buildStationCard(stationStat);
            }),

            const Divider(thickness: 2, height: 32),

            // 總計
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '統計總計',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._buildSummaryStats(stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(Map<String, dynamic> stationStat) {
    final station = stationStat['station'] as Station;
    final roundTripStudents = stationStat['roundTripStudents'] as List<String>;
    final leaveBaseStudents = stationStat['leaveBaseStudents'] as List<String>;
    final returnBaseStudents =
        stationStat['returnBaseStudents'] as List<String>;
    final totalCount = stationStat['totalCount'] as int;
    final cost = stationStat['cost'] as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${station.name}(\$${station.roundTripPrice})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (roundTripStudents.isNotEmpty) ...[
              const Text('來回：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(roundTripStudents.join(', ')),
              const SizedBox(height: 8),
            ],

            if (leaveBaseStudents.isNotEmpty) ...[
              Text(
                '離營(\$${station.price})：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(leaveBaseStudents.join(', ')),
              const SizedBox(height: 8),
            ],

            if (returnBaseStudents.isNotEmpty) ...[
              Text(
                '回營(\$${station.price})：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(returnBaseStudents.join(', ')),
              const SizedBox(height: 8),
            ],

            const Divider(),
            Text(
              '${station.name} 共 $totalCount 員搭乘 (\$$cost)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSummaryStats(Map<String, dynamic> stats) {
    final stationStats = stats['stationStats'] as List;

    return [
      ...stationStats.map((s) {
        final station = s['station'] as Station;
        final totalCount = s['totalCount'] as int;
        final cost = s['cost'] as int;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${station.name} 共 $totalCount 員搭乘 (\$$cost)',
            style: const TextStyle(fontSize: 16),
          ),
        );
      }),
      const SizedBox(height: 16),
      Text(
        '專車人數 共 ${stats['totalStudents']} 員',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        '專車費用 共 ${stats['totalCost']} 元',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ];
  }

  void _copyToClipboard(BuildContext context, Map<String, dynamic> stats) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('M/d').format(record.date);

    buffer.writeln('$dateStr ${record.className} 專車來回');
    buffer.writeln();

    final stationStats = stats['stationStats'] as List;
    for (final s in stationStats) {
      final station = s['station'] as Station;
      final roundTripStudents = s['roundTripStudents'] as List<String>;
      final leaveBaseStudents = s['leaveBaseStudents'] as List<String>;
      final returnBaseStudents = s['returnBaseStudents'] as List<String>;

      if (roundTripStudents.isNotEmpty) {
        buffer.writeln(
          '${station.name}(\$${station.roundTripPrice}) : ${roundTripStudents.join(', ')}',
        );
      }

      if (leaveBaseStudents.isNotEmpty) {
        buffer.writeln(
          '離營(\$${station.price}) : ${leaveBaseStudents.join(', ')}',
        );
      }

      if (returnBaseStudents.isNotEmpty) {
        buffer.writeln(
          '回營(\$${station.price}) : ${returnBaseStudents.join(', ')}',
        );
      }

      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('==================');

    for (final s in stationStats) {
      final station = s['station'] as Station;
      final totalCount = s['totalCount'] as int;
      final cost = s['cost'] as int;
      buffer.writeln('${station.name} 共 $totalCount 員搭乘 (\$$cost)');
    }

    buffer.writeln();
    buffer.writeln('專車人數 共 ${stats['totalStudents']} 員');
    buffer.writeln('專車費用 共 ${stats['totalCost']} 元');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已複製到剪貼簿')));
  }

  void _duplicateRecord(BuildContext context, AppProvider provider) {
    final duplicated = provider.duplicateRecord(record);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRecordPage(existingRecord: duplicated),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此記錄嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteRecord(record.id);
              if (context.mounted) {
                Navigator.pop(context); // 關閉對話框
                Navigator.pop(context); // 返回列表頁
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已刪除記錄')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}
