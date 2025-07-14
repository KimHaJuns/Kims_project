// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(const MyApp());

class Event {
  String title;
  Event(this.title);

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Event && runtimeType == other.runtimeType && title == other.title;

  @override
  int get hashCode => title.hashCode;
}

DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

Map<DateTime, List<Event>> events = {
  normalizeDate(DateTime.utc(2025, 7, 13)): [Event('title'), Event('title2')],
  normalizeDate(DateTime.utc(2025, 7, 14)): [Event('title3')],
};

List<Event> getEventsForDay(DateTime day) => events[normalizeDate(day)] ?? [];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '달력앱',
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CalendarPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = normalizeDate(DateTime.now());
  int _lastPressedTimestamp = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('달력앱')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => pickAndShowImage(context),
                icon: const Icon(Icons.image),
                label: const Text("파일 추가"),
              ),
              ElevatedButton.icon(
                onPressed: () => showAddEventDialog(context),
                icon: const Icon(Icons.event),
                label: const Text("일정 추가"),
              ),
            ],
          ),
          Expanded(
            child: TableCalendar(
              eventLoader: getEventsForDay,
              calendarStyle: CalendarStyle(
                markerSize: 10.0,
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(color: Colors.grey),
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                todayTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              locale: 'ko_KR',
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              focusedDay: focusedDay,
              firstDay: DateTime.utc(2015, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              daysOfWeekHeight: 20,
              rowHeight: 80,
              onPageChanged: (fd) => setState(() => focusedDay = fd),
              onDaySelected: (sel, fd) {
                final normDate = normalizeDate(sel);
                final now = DateTime.now().millisecondsSinceEpoch;

                if (now - _lastPressedTimestamp < 500 && isSameDay(selectedDay, normDate)) {
                  final eventsForDay = getEventsForDay(normDate);
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 500,
                        height: 600,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${normDate.year}년 ${normDate.month}월 ${normDate.day}일",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...eventsForDay.map((e) => Text("• ${e.title}")),
                            if (eventsForDay.isEmpty)
                              const Text("등록된 일정이 없습니다."),
                          ],
                        ),
                      ),
                    ),
                  );
                  _lastPressedTimestamp = 0;
                } else {
                  _lastPressedTimestamp = now;
                  setState(() {
                    selectedDay = normDate;
                    focusedDay = fd;
                  });
                }
              },
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            ),
          ),
        ],
      ),
    );
  }

  void showAddEventDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '정보 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('선택 날짜:'),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2015),
                        lastDate: DateTime(2035),
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                final input = controller.text.trim();
                if (input.isNotEmpty) {
                  final norm = normalizeDate(selectedDate);
                  setState(() {
                    events[norm] = [...getEventsForDay(norm), Event(input)];
                    selectedDay = norm;
                    focusedDay = norm;
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> pickAndShowImage(BuildContext context) async {
  bool showButton = false;
  XFile? selectedImage;
  String status = '이미지를 선택해주세요';
  final picker = ImagePicker();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (showButton)
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  child: const Text('적용'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ImageApplyPage()),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            if (selectedImage != null)
              CircleAvatar(
                radius: 70,
                backgroundImage: FileImage(File(selectedImage!.path)),
              ),
            const SizedBox(height: 40),
            Text(status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    showButton = true;
                    selectedImage = image;
                    status = '이미지가 선택되었습니다.';
                  });
                } else {
                  setState(() => status = '아무것도 선택하지 않았습니다.');
                }
              },
              child: const Text('이미지 선택'),
            ),
          ],
        ),
      ),
    ),
  );
}



class ImageApplyPageState extends StatefulWidget {
  const ImageApplyPageState({super.key});

  @override
  State<ImageApplyPage> createState() => _ImageApplyPageState();
}

class ImageApplyPage extends StatefulWidget {
  const ImageApplyPage({super.key});

  @override
  State<ImageApplyPage> createState() => _ImageApplyPageState();
}

class _ImageApplyPageState extends State<ImageApplyPage> {
  List<Map<String, String>> items = [
    {'id': '1', 'title': '회의', 'date': '2025-07-15'},
    {'id': '2', 'title': '약속', 'date': '2025-07-16'},
  ];

  List<bool> checked = [];

  @override
  void initState() {
    super.initState();
    checked = List.generate(items.length, (_) => false);
  }

  DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('적용할 일정 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '일정을 추가하시려면 체크박스를 클릭하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ✅ 적용 버튼 표시 (조건부)
            if (checked.contains(true))
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    for (int i = 0; i < checked.length; i++) {
                      if (checked[i]) {
                        final item = items[i];
                        final title = item['title'] ?? '';
                        final dateStr = item['date'] ?? '';
                        try {
                          final date = normalizeDate(DateTime.parse(dateStr));
                          events.putIfAbsent(date, () => []);
                          events[date]!.add(Event(title));
                        } catch (e) {
                          // 날짜 파싱 실패 시 무시하거나 로그 출력
                        }
                      }
                    }
                    Navigator.of(context).pop(); // 페이지 닫기
                  },
                  child: const Text('적용'),
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = item['id'] ?? '';
                    final title = item['title'] ?? '';
                    final date = item['date'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked[index],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  checked[index] = value;
                                });
                              }
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  checked[index] = !checked[index];
                                });
                              },
                              child: Text('$id | $title | $date'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              final controller = TextEditingController(text: title);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('일정 수정'),
                                    content: TextField(controller: controller),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('취소'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            items[index]['title'] = controller.text;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: const Text('저장'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                items.removeAt(index);
                                checked.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
