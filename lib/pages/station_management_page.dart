import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../providers/app_provider.dart';

/// 站點管理頁面
class StationManagementPage extends StatelessWidget {
  const StationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('站點管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.stations.isEmpty) {
            return const Center(child: Text('尚無站點，請點擊右下角新增'));
          }

          return ListView.builder(
            itemCount: provider.stations.length,
            itemBuilder: (context, index) {
              final station = provider.stations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '單程: \$${station.price} | 來回: \$${station.roundTripPrice}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context, station),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, station),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    _showStationDialog(context, null);
  }

  void _showEditDialog(BuildContext context, Station station) {
    _showStationDialog(context, station);
  }

  void _showStationDialog(BuildContext context, Station? existingStation) {
    final nameController = TextEditingController(
      text: existingStation?.name ?? '',
    );
    final priceController = TextEditingController(
      text: existingStation?.price.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingStation == null ? '新增站點' : '編輯站點'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '站點名稱',
                  hintText: '例如：蘆竹',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: '單程價格',
                  hintText: '例如：420（來回自動為2倍）',
                  helperText: '來回價格 = 單程價格 × 2',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text);

              if (name.isEmpty || price == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('請填寫完整資訊')));
                return;
              }

              final provider = Provider.of<AppProvider>(context, listen: false);

              if (existingStation == null) {
                // 新增
                final newStation = Station(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  price: price,
                );
                await provider.addStation(newStation);
              } else {
                // 編輯
                final updatedStation = existingStation.copyWith(
                  name: name,
                  price: price,
                );
                await provider.updateStation(
                  existingStation.id,
                  updatedStation,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingStation == null ? '已新增站點' : '已更新站點'),
                  ),
                );
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Station station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除站點「${station.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.deleteStation(station.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已刪除站點')));
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
