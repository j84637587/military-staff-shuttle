import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/shuttle_record.dart';
import '../models/student_ride.dart';
import '../models/station.dart';
import 'record_detail_page.dart';

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
                maxHeight: MediaQuery.of(context).size.height * 0.9,
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
        final station = provider.getStationById(stationId);
        final isDeleted = station.isDeleted;

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
          color: isDeleted ? Colors.grey[200] : null,
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isDeleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '已刪除',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
          getStationById: provider.getStationById,
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
      if (widget.existingRecord == null) {
        // 建立新記錄後，跳轉到詳細頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecordDetailPage(record: record),
          ),
        );
      } else {
        // 編輯記錄後，返回上一頁
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已更新記錄')));
      }
    }
  }
}

/// 學員站點分配頁面
class StudentAssignmentPage extends StatefulWidget {
  final int totalStudents;
  final List<Station> stations;
  final Map<String, StudentRide> existingRides;
  final Function(Map<String, StudentRide>) onSave;
  final Station Function(String) getStationById;

  const StudentAssignmentPage({
    super.key,
    required this.totalStudents,
    required this.stations,
    required this.existingRides,
    required this.onSave,
    required this.getStationById,
  });

  @override
  State<StudentAssignmentPage> createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
  late Map<String, StudentRide> _rides;
  final TextEditingController _searchController = TextEditingController();
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
      (index) => (index + 1).toString().padLeft(3, '0'),
    );

    // 搜尋過濾
    if (_searchController.text.isNotEmpty) {
      students = students
          .where((s) => s.contains(_searchController.text))
          .toList();
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                const SizedBox(width: 12),
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

          // 過濾區
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Column(
              children: [
                // 快速分配模式選擇區
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 站點選擇
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.stations.map((station) {
                          final isSelected =
                              _quickSelectStationId == station.id;
                          return ChoiceChip(
                            label: Text(
                              station.name,
                              style: const TextStyle(fontSize: 12),
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      if (_quickSelectStationId != null) ...[
                        const SizedBox(height: 6),
                        // 搭乘類型選擇（與站點對齊）
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sync_alt, size: 14),
                                  SizedBox(width: 2),
                                  Text('來回', style: TextStyle(fontSize: 11)),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            ChoiceChip(
                              label: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, size: 14),
                                  SizedBox(width: 2),
                                  Text('離營', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                              selected:
                                  _quickSelectRideType == RideType.leaveBase,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _quickSelectRideType = RideType.leaveBase;
                                  });
                                }
                              },
                              selectedColor: Colors.orange[300],
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            ChoiceChip(
                              label: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.login, size: 14),
                                  SizedBox(width: 2),
                                  Text('回營', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                              selected:
                                  _quickSelectRideType == RideType.returnBase,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _quickSelectRideType = RideType.returnBase;
                                  });
                                }
                              },
                              selectedColor: Colors.orange[300],
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 每行5個
                          childAspectRatio: 1, // 正方形
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final studentNumber = _filteredStudents[index];
                      final ride = _rides[studentNumber];
                      return _buildStudentGridItem(studentNumber, ride);
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
            onPressed: _rides.isEmpty ? null : () => _showClearAllDialog(),
            child: const Icon(Icons.clear_all),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildStudentGridItem(String studentNumber, StudentRide? ride) {
    final station = ride != null ? widget.getStationById(ride.stationId) : null;
    final isAssigned = ride != null;

    return InkWell(
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
      child: Container(
        decoration: BoxDecoration(
          color: isAssigned ? Colors.blue[400] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 學號
            Text(
              studentNumber,
              style: TextStyle(
                color: isAssigned ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isAssigned && station != null) ...[
              const SizedBox(height: 4),
              // 站點名稱
              Text(
                station.name,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // 搭乘類型圖標
              Icon(
                ride.rideType == RideType.roundTrip
                    ? Icons.sync_alt
                    : ride.rideType == RideType.leaveBase
                    ? Icons.logout
                    : Icons.login,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: RadioGroup<String>(
                      groupValue: selectedStationId,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStationId = value;
                          });
                        }
                      },
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.stations.map((station) {
                          final isSelected = selectedStationId == station.id;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedStationId = station.id;
                              });
                            },
                            child: Container(
                              width: 95, // 固定寬度，確保每行約3個
                              height: 65, // 固定高度
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue[50]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Radio<String>(
                                    value: station.id,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Text(
                                    station.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                RadioGroup<RideType>(
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedRideType = value;
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRideType = RideType.roundTrip;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedRideType == RideType.roundTrip
                                  ? Colors.blue[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selectedRideType == RideType.roundTrip
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: selectedRideType == RideType.roundTrip
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Radio<RideType>(
                                  value: RideType.roundTrip,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Icon(Icons.sync_alt, size: 18),
                                const Text(
                                  '來回',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRideType = RideType.leaveBase;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedRideType == RideType.leaveBase
                                  ? Colors.blue[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selectedRideType == RideType.leaveBase
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: selectedRideType == RideType.leaveBase
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Radio<RideType>(
                                  value: RideType.leaveBase,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Icon(Icons.logout, size: 18),
                                const Text(
                                  '離營',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRideType = RideType.returnBase;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedRideType == RideType.returnBase
                                  ? Colors.blue[50]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selectedRideType == RideType.returnBase
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: selectedRideType == RideType.returnBase
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Radio<RideType>(
                                  value: RideType.returnBase,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Icon(Icons.login, size: 18),
                                const Text(
                                  '回營',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          hintText: '001',
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
                  initialValue: selectedStationId,
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
                RadioGroup<RideType>(
                  groupValue: selectedRideType,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedRideType = value;
                      });
                    }
                  },
                  child: Column(
                    children: [
                      ListTile(
                        leading: Radio<RideType>(value: RideType.roundTrip),
                        title: const Text('來回'),
                        onTap: () {
                          setDialogState(() {
                            selectedRideType = RideType.roundTrip;
                          });
                        },
                      ),
                      ListTile(
                        leading: Radio<RideType>(value: RideType.leaveBase),
                        title: const Text('離營'),
                        onTap: () {
                          setDialogState(() {
                            selectedRideType = RideType.leaveBase;
                          });
                        },
                      ),
                      ListTile(
                        leading: Radio<RideType>(value: RideType.returnBase),
                        title: const Text('回營'),
                        onTap: () {
                          setDialogState(() {
                            selectedRideType = RideType.returnBase;
                          });
                        },
                      ),
                    ],
                  ),
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
                    start < 1 ||
                    start > end ||
                    end > widget.totalStudents) {
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
