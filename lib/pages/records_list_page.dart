import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import 'record_detail_page.dart';
import 'create_record_page.dart';

/// 記錄列表頁面
class RecordsListPage extends StatelessWidget {
  const RecordsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('專車記錄'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.records.isEmpty) {
            return const Center(child: Text('尚無記錄，請點擊右下角新增'));
          }

          return ListView.builder(
            itemCount: provider.records.length,
            itemBuilder: (context, index) {
              final record = provider.records[index];
              final dateStr = DateFormat('yyyy/MM/dd').format(record.date);
              final stats = provider.calculateStatistics(record);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    '$dateStr ${record.className}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '搭乘人數: ${stats['totalStudents']} 員 | 總費用: \$${stats['totalCost']}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordDetailPage(record: record),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRecordPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
