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
      title: '캘린더 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
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
  DateTime _focusedMonth = DateTime.now();
  final Map<String, List<String>> _events = {};
  PlatformFile? _selectedFile;

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

  Future<void> _handleFilePick(
    BuildContext context,
    void Function(void Function()) setModalState,
  ) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (!context.mounted) return;

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      final ext = pickedFile.name.split('.').last.toLowerCase();

      if (["png", "jpg", "jpeg", "pdf"].contains(ext)) {
        setModalState(() {
          _selectedFile = pickedFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 또는 PDF 파일만 선택 가능합니다.')),
        );
      }
    }
  }

  Future<void> _showFilePickerSheet() async {
    _selectedFile = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleFilePick(context, setModalState),
                        child: const Text('파일 선택'),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          _selectedFile?.name ?? '선택된 파일 없음',
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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

  void _addEvent(DateTime day) {
    final formatted = DateFormat('yyyy-MM-dd').format(day);
    final controller = TextEditingController();

    showDialog(
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
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDayEvents(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final todayEvents = _events[key] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    '선택한 날짜: $key',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...todayEvents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    return Row(
                      children: [
                        Expanded(child: Text('• $event')),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                          onPressed: () {
                            final controller = TextEditingController(text: event);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('일정 수정'),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(hintText: '새 일정 입력'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final newText = controller.text.trim();
                                      if (newText.isNotEmpty) {
                                        setState(() {
                                          _events[key]![index] = newText;
                                        });
                                        setModalState(() {});
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: const Text('저장'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('삭제 확인'),
                                content: const Text('이 일정을 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _events[key]!.removeAt(index);
                                      });
                                      setModalState(() {});
                                      Navigator.pop(context);
                                    },
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("일정 추가"),
                      onPressed: () {
                        final controller = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('새 일정 추가'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: '일정 입력'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final newText = controller.text.trim();
                                  if (newText.isNotEmpty) {
                                    setState(() {
                                      _events.putIfAbsent(key, () => []).add(newText);
                                    });
                                    setModalState(() {});
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('추가'),
                              ),
                            ],
                          ),
                        );
                      },
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
            style: const TextStyle(fontWeight: FontWeight.bold),
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
          onTap: () => _showDayEvents(currentDate),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$day', style: const TextStyle(fontSize: 16)),
                ...todayEvents.take(2).map(
                      (e) => Text(
                        e,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () => _addEvent(currentDate),
                    child: const Icon(Icons.add, size: 30, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return days;
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
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}
