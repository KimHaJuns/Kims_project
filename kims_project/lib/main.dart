import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calendar with Events',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Future<void> _handleFilePick(BuildContext context, void Function(void Function()) setModalState) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any
  );

  if (!context.mounted) return;

  if (result != null && result.files.isNotEmpty) {
    final pickedFile = result.files.first;
    final ext = pickedFile.name.split('.').last.toLowerCase();

    if (['png', 'jpg', 'jpeg', 'pdf'].contains(ext)) {
      setModalState(() {
        _selectedFile = pickedFile;
      });
    } else {
      // ❌ 그 외 확장자는 무시 + 경고 메시지 출력
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지(png, jpg, jpeg) 또는 PDF 파일만 선택할 수 있습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

  DateTime _focusedMonth = DateTime.now();
  final Map<String, List<String>> _events = {};

  PlatformFile? _selectedFile;


  void _addEvent(DateTime day) async {
    final formatted = DateFormat('yyyy-MM-dd').format(day);
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${DateFormat('MM/dd').format(day)} 일정 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '일정 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _events.putIfAbsent(formatted, () => []).add(text);
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCalendar() {
    final days = <Widget>[];
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = DateTime(year, month + 1, 0).day;

    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    days.addAll(weekDays.map((d) => Center(
          child: Text(
            d,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        )));

    for (int i = 0; i < startWeekday; i++) {
      days.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= totalDays; day++) {
      final currentDate = DateTime(year, month, day);
      final key = DateFormat('yyyy-MM-dd').format(currentDate);
      final todayEvents = _events[key] ?? [];

      days.add(
        GestureDetector(
          onTap: () => _addEvent(currentDate),
          child: Container(
            margin: const EdgeInsets.all(0.5),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  '$day',
                  style: const TextStyle(fontSize: 12),
                ),
                ...todayEvents.map((e) => Text(
                      e,
                      style: const TextStyle(fontSize: 8, color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return days;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  Future<void> _showFilePickerSheet() async {
  _selectedFile = null; // 초기화

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                   ElevatedButton(
                      onPressed: () => _handleFilePick(context, setModalState),  // context를 안전하게 전달
                      child: const Text('파일 선택'),
                    ),

                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : '선택된 파일 없음',
                        style: const TextStyle(fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedFile != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('파일 적용됨: ${_selectedFile!.name}')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('적용'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('yyyy년 MM월').format(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevMonth),
                Text(
                  monthTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _nextMonth),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: _buildCalendar(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilePickerSheet,
        backgroundColor: Colors.blue,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }
}