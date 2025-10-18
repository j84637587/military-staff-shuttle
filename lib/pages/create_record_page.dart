import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/shuttle_record.dart';
import '../models/student_ride.dart';
import '../models/station.dart';

/// 建立/編輯專車記錄頁面
class CreateRecordPage extends StatefulWidget {
  final ShuttleRecord? existingRecord;

  const CreateRecordPage({super.key, this.existingRecord});

  @override
  State<CreateRecordPage> createState() => _CreateRecordPageState();
}

class _CreateRecordPageState extends State<CreateRecordPage> {
  late DateTime _selectedDate;
  final _classNameController = TextEditingController();
  final _totalStudentsController = TextEditingController();

  // 學員搭乘資料 Map: studentNumber -> StudentRide
  final Map<String, StudentRide> _studentRides = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _selectedDate = widget.existingRecord!.date;
      _classNameController.text = widget.existingRecord!.className;
      _totalStudentsController.text = widget.existingRecord!.totalStudents
          .toString();

      // 載入現有的搭乘資料
      for (final ride in widget.existingRecord!.rides) {
        _studentRides[ride.studentNumber] = ride;
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _totalStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.existingRecord == null ? '新增記錄' : '編輯記錄'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 基本資訊輸入區
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // 日期選擇
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('日期'),
                    subtitle: Text(
                      DateFormat('yyyy/MM/dd').format(_selectedDate),
                    ),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 8),
                  // 班級名稱
                  TextField(
                    controller: _classNameController,
                    decoration: const InputDecoration(
                      labelText: '班級名稱',
                      hintText: '例如：步二連',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 學員總數
                  TextField(
                    controller: _totalStudentsController,
                    decoration: const InputDecoration(
                      labelText: '學員總數',
                      hintText: '例如：180',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),

            // 學員分配按鈕
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.stations.isEmpty
                          ? null
                          : () => _showStudentAssignment(context, provider),
                      icon: const Icon(Icons.people),
                      label: const Text('分配學員站點'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 已分配學員列表
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: _buildAssignedStudentsList(provider),
            ),
            // 底部留白，避免被底部按鈕遮擋
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _studentRides.isEmpty
                ? null
                : () => _saveRecord(provider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              widget.existingRecord == null ? '建立記錄' : '儲存變更',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedStudentsList(AppProvider provider) {
    if (_studentRides.isEmpty) {
      return const Center(child: Text('尚未分配學員\n請點擊上方按鈕開始分配'));
    }

    // 按站點分組
    final groupedByStation = <String, List<StudentRide>>{};
    for (final ride in _studentRides.values) {
      groupedByStation.putIfAbsent(ride.stationId, () => []).add(ride);
    }

    return ListView.builder(
      itemCount: groupedByStation.length,
      itemBuilder: (context, index) {
        final stationId = groupedByStation.keys.elementAt(index);
        final rides = groupedByStation[stationId]!;
        final station = provider.stations.firstWhere(
          (s) => s.id == stationId,
          orElse: () => Station(id: stationId, name: '未知站點', price: 0),
        );

        final roundTripStudents = rides
            .where((r) => r.rideType == RideType.roundTrip)
            .map((r) => r.studentNumber)
            .toList();
        final oneWayStudents = rides
            .where((r) => r.rideType != RideType.roundTrip)
            .map((r) => r.studentNumber)
            .toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('共 ${rides.length} 員'),
            children: [
              if (roundTripStudents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '來回：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(roundTripStudents.join(', ')),
                    ],
                  ),
                ),
              if (oneWayStudents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '單程：',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(oneWayStudents.join(', ')),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showStudentAssignment(BuildContext context, AppProvider provider) {
    final totalStr = _totalStudentsController.text.trim();
    if (totalStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先輸入學員總數')));
      return;
    }

    final total = int.parse(totalStr);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAssignmentPage(
          totalStudents: total,
          stations: provider.stations,
          existingRides: Map.from(_studentRides),
          onSave: (rides) {
            setState(() {
              _studentRides.clear();
              _studentRides.addAll(rides);
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveRecord(AppProvider provider) async {
    final className = _classNameController.text.trim();
    final totalStr = _totalStudentsController.text.trim();

    if (className.isEmpty || totalStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請填寫完整資訊')));
      return;
    }

    final record = ShuttleRecord(
      id:
          widget.existingRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      className: className,
      totalStudents: int.parse(totalStr),
      rides: _studentRides.values.toList(),
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    if (widget.existingRecord == null) {
      await provider.addRecord(record);
    } else {
      await provider.updateRecord(record.id, record);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingRecord == null ? '已建立記錄' : '已更新記錄'),
        ),
      );
    }
  }
}

/// 學員站點分配頁面
class StudentAssignmentPage extends StatefulWidget {
  final int totalStudents;
  final List<Station> stations;
  final Map<String, StudentRide> existingRides;
  final Function(Map<String, StudentRide>) onSave;

  const StudentAssignmentPage({
    super.key,
    required this.totalStudents,
    required this.stations,
    required this.existingRides,
    required this.onSave,
  });

  @override
  State<StudentAssignmentPage> createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
  late Map<String, StudentRide> _rides;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyUnassigned = false;
  String? _filterStationId;

  // 快速分配模式
  String? _quickSelectStationId;
  RideType _quickSelectRideType = RideType.roundTrip;

  @override
  void initState() {
    super.initState();
    _rides = Map.from(widget.existingRides);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredStudents {
    List<String> students = List.generate(
      widget.totalStudents,
      (index) => index.toString().padLeft(3, '0'),
    );

    // 搜尋過濾
    if (_searchQuery.isNotEmpty) {
      students = students.where((s) => s.contains(_searchQuery)).toList();
    }

    // 只顯示未分配
    if (_showOnlyUnassigned) {
      students = students.where((s) => !_rides.containsKey(s)).toList();
    }

    // 依站點過濾
    if (_filterStationId != null) {
      students = students
          .where((s) => _rides[s]?.stationId == _filterStationId)
          .toList();
    }

    return students;
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = _rides.length;
    final unassignedCount = widget.totalStudents - assignedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分配學員站點'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '完成',
            onPressed: () {
              widget.onSave(_rides);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 統計卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '已分配',
                    assignedCount.toString(),
                    Icons.check_circle,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    '未分配',
                    unassignedCount.toString(),
                    Icons.pending,
                    Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 搜尋和過濾區
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // 快速分配模式選擇區
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '快速分配模式',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          if (_quickSelectStationId != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _quickSelectStationId = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('清除'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange[700],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 站點選擇
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.stations.map((station) {
                          final isSelected =
                              _quickSelectStationId == station.id;
                          return ChoiceChip(
                            label: Text(station.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _quickSelectStationId = selected
                                    ? station.id
                                    : null;
                              });
                            },
                            selectedColor: Colors.orange[300],
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                      if (_quickSelectStationId != null) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        // 搭乘類型選擇
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_alt, size: 16),
                                    SizedBox(width: 4),
                                    Text('來回'),
                                  ],
                                ),
                                selected:
                                    _quickSelectRideType == RideType.roundTrip,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _quickSelectRideType = RideType.roundTrip;
                                    });
                                  }
                                },
                                selectedColor: Colors.orange[300],
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_forward, size: 16),
                                    SizedBox(width: 4),
                                    Text('單程'),
                                  ],
                                ),
                                selected:
                                    _quickSelectRideType == RideType.returnOnly,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _quickSelectRideType =
                                          RideType.returnOnly;
                                    });
                                  }
                                },
                                selectedColor: Colors.orange[300],
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💡 選擇站點和類型後，點擊學員即可快速分配',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 搜尋框
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋學號...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // 快速過濾按鈕
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: '全部',
                        isSelected:
                            !_showOnlyUnassigned && _filterStationId == null,
                        onTap: () {
                          setState(() {
                            _showOnlyUnassigned = false;
                            _filterStationId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: '未分配',
                        count: unassignedCount,
                        isSelected: _showOnlyUnassigned,
                        onTap: () {
                          setState(() {
                            _showOnlyUnassigned = !_showOnlyUnassigned;
                            _filterStationId = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...widget.stations.map((station) {
                        final count = _rides.values
                            .where((r) => r.stationId == station.id)
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: station.name,
                            count: count,
                            isSelected: _filterStationId == station.id,
                            onTap: () {
                              setState(() {
                                _filterStationId =
                                    _filterStationId == station.id
                                    ? null
                                    : station.id;
                                _showOnlyUnassigned = false;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 學員列表
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '沒有符合條件的學員',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final studentNumber = _filteredStudents[index];
                      final ride = _rides[studentNumber];
                      return _buildStudentCard(studentNumber, ride);
                    },
                  ),
          ),
        ],
      ),
      // 快速操作按鈕
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'batch',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.playlist_add),
            onPressed: () => _showBatchAssignDialog(),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'clear',
            backgroundColor: Colors.red,
            child: const Icon(Icons.clear_all),
            onPressed: _rides.isEmpty ? null : () => _showClearAllDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String studentNumber, StudentRide? ride) {
    final station = ride != null
        ? widget.stations.firstWhere(
            (s) => s.id == ride.stationId,
            orElse: () => Station(id: ride.stationId, name: '未知站點', price: 0),
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ride != null ? Colors.blue[200]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 如果快速分配模式已啟用，直接分配
          if (_quickSelectStationId != null) {
            _quickAssignStudent(studentNumber);
          } else {
            // 否則打開詳細對話框
            _showAssignDialog(studentNumber, ride);
          }
        },
        onLongPress: () => _showAssignDialog(studentNumber, ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 學號
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ride != null ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    studentNumber,
                    style: TextStyle(
                      color: ride != null ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 站點資訊
              Expanded(
                child: ride != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                station!.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ride.rideType == RideType.roundTrip
                                    ? '來回 (\$${station.roundTripPrice})'
                                    : '單程 (\$${station.price})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        '尚未分配',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
              ),
              // 操作按鈕
              IconButton(
                icon: Icon(
                  ride != null ? Icons.edit : Icons.add_circle_outline,
                  color: ride != null ? Colors.blue : Colors.green,
                ),
                onPressed: () => _showAssignDialog(studentNumber, ride),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(String studentNumber, StudentRide? currentRide) {
    String? selectedStationId = currentRide?.stationId;
    RideType selectedRideType = currentRide?.rideType ?? RideType.roundTrip;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('學員 $studentNumber'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '選擇站點',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...widget.stations.map((station) {
                  final isSelected = selectedStationId == station.id;
                  return Card(
                    color: isSelected ? Colors.blue[50] : null,
                    child: RadioListTile<String>(
                      value: station.id,
                      groupValue: selectedStationId,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStationId = value;
                        });
                      },
                      title: Text(
                        station.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '單程: \$${station.price} / 來回: \$${station.roundTripPrice}',
                      ),
                      selected: isSelected,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  '搭乘類型',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                RadioListTile<RideType>(
                  value: RideType.roundTrip,
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRideType = value!;
                    });
                  },
                  title: const Text('來回'),
                  secondary: const Icon(Icons.sync_alt),
                ),
                RadioListTile<RideType>(
                  value: RideType.returnOnly,
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRideType = value!;
                    });
                  },
                  title: const Text('單程'),
                  secondary: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          actions: [
            if (currentRide != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _rides.remove(studentNumber);
                  });
                  Navigator.pop(context);
                },
                child: const Text('移除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: selectedStationId == null
                  ? null
                  : () {
                      setState(() {
                        _rides[studentNumber] = StudentRide(
                          studentNumber: studentNumber,
                          stationId: selectedStationId!,
                          rideType: selectedRideType,
                        );
                      });
                      Navigator.pop(context);
                    },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _quickAssignStudent(String studentNumber) {
    if (_quickSelectStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先選擇站點'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _rides[studentNumber] = StudentRide(
        studentNumber: studentNumber,
        stationId: _quickSelectStationId!,
        rideType: _quickSelectRideType,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('學員 $studentNumber 已分配'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showBatchAssignDialog() {
    String? selectedStationId;
    RideType selectedRideType = RideType.roundTrip;
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('批次分配'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '學號範圍',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        decoration: const InputDecoration(
                          labelText: '起始',
                          hintText: '000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('~'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        decoration: const InputDecoration(
                          labelText: '結束',
                          hintText: '010',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '選擇站點',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStationId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('請選擇站點'),
                  items: widget.stations.map((station) {
                    return DropdownMenuItem(
                      value: station.id,
                      child: Text(station.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStationId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  '搭乘類型',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<RideType>(
                  value: RideType.roundTrip,
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRideType = value!;
                    });
                  },
                  title: const Text('來回'),
                ),
                RadioListTile<RideType>(
                  value: RideType.returnOnly,
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRideType = value!;
                    });
                  },
                  title: const Text('單程'),
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
              onPressed: () {
                final start = int.tryParse(startController.text);
                final end = int.tryParse(endController.text);

                if (start == null ||
                    end == null ||
                    selectedStationId == null ||
                    start > end ||
                    end >= widget.totalStudents) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('請輸入有效的學號範圍和站點')),
                  );
                  return;
                }

                setState(() {
                  for (int i = start; i <= end; i++) {
                    final studentNumber = i.toString().padLeft(3, '0');
                    _rides[studentNumber] = StudentRide(
                      studentNumber: studentNumber,
                      stationId: selectedStationId!,
                      rideType: selectedRideType,
                    );
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已批次分配 ${end - start + 1} 名學員')),
                );
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有分配'),
        content: const Text('確定要清除所有學員的站點分配嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _rides.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已清除所有分配')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}
