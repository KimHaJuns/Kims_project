// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

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

void debugLog(String message) {
  if (kDebugMode) {
    print(message);
  }
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
                label: const Text("사진 입력"),
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
                    builder: (ctx) {
                      return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Padding(
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
                                  if (eventsForDay.isEmpty)
                                    const Text("등록된 일정이 없습니다."),
                                  ...eventsForDay.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    Event event = entry.value;
                                    final controller = TextEditingController(text: event.title);

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text("• ${event.title}")),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
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
                                                          events[normDate]![index] = Event(controller.text);
                                                        });
                                                        setModalState(() {}); // 모달 갱신
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
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text('삭제 확인'),
                                                  content: const Text('정말 삭제하시겠습니까?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('취소'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          events[normDate]!.removeAt(index);
                                                          if (events[normDate]!.isEmpty) {
                                                            events.remove(normDate);
                                                          }
                                                        });
                                                        setModalState(() {}); // 모달 갱신
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('삭제'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  })
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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
    void showMonthDayPickerDialog(
        BuildContext context,
        DateTime initialDate,
        void Function(DateTime) onDatePicked,
        ) {
      int selectedYear = initialDate.year;
      int selectedMonth = initialDate.month;
      int selectedDay = initialDate.day;

      DateTime getLastDate(int year, int month) {
        return (month == 12)
            ? DateTime(year + 1, 1, 0)
            : DateTime(year, month + 1, 0);
      }

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            final firstDate = DateTime(selectedYear, selectedMonth, 1);
            final lastDate = getLastDate(selectedYear, selectedMonth);

            // 🛠 초기 날짜 범위 보정
            DateTime initDate = DateTime(selectedYear, selectedMonth, selectedDay);
            if (initDate.isBefore(firstDate)) {
              initDate = firstDate;
              selectedDay = initDate.day;
            } else if (initDate.isAfter(lastDate)) {
              initDate = lastDate;
              selectedDay = initDate.day;
            }

            return AlertDialog(
              title: const Text('월-일 선택'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<int>(
                          value: selectedYear,
                          items: List.generate(21, (i) => 2015 + i)
                              .map((y) => DropdownMenuItem(value: y, child: Text('$y 년')))
                              .toList(),
                          onChanged: (y) {
                            if (y == null) return;
                            setState(() {
                              selectedYear = y;
                              final maxDay = getLastDate(selectedYear, selectedMonth).day;
                              if (selectedDay > maxDay) selectedDay = maxDay;
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        DropdownButton<int>(
                          value: selectedMonth,
                          items: List.generate(12, (i) => i + 1)
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m 월')))
                              .toList(),
                          onChanged: (m) {
                            if (m == null) return;
                            setState(() {
                              selectedMonth = m;
                              final maxDay = getLastDate(selectedYear, selectedMonth).day;
                              if (selectedDay > maxDay) selectedDay = maxDay;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: initDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                        onDateChanged: (date) {
                          setState(() {
                            selectedDay = date.day;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final picked = DateTime(selectedYear, selectedMonth, selectedDay);
                    onDatePicked(picked);
                    Navigator.of(context).pop();
                  },
                  child: const Text('선택'),
                ),
              ],
            );
          },
        ),
      );
    }
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () {
                      showMonthDayPickerDialog(context, selectedDate, (picked) {
                        setState(() => selectedDate = picked);
                      });
                    },
                  ),
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

// 예: 이미지 파일과 함께 POST 요청 보내는 함수
Future<List<dynamic>?> uploadImageAndGetList(File imageFile) async {
  var uri = Uri.parse('https://your-server.com/upload'); //주소 변경 필요.

  var request = http.MultipartRequest('POST', uri);

  // 이미지 파일 추가 ('image'는 서버에서 받는 필드명)
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  try {
    // 요청 보내기
    var streamedResponse = await request.send();

    // 스트림 응답을 Response로 변환
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // 서버에서 JSON 형태로 리스트를 응답한다고 가정
      final data = jsonDecode(response.body);

      if (data is List) {
        return data; // JSON 리스트 반환
      } else if (data is Map && data['list'] is List) {
        return data['list']; // 예: { "list": [...] } 형태일 때
      } else {
        debugLog('응답 데이터가 리스트가 아닙니다.');
        return null;
      }
    } else {
      debugLog('서버 오류: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    debugLog('요청 실패: $e');
    return null;
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
                    onPressed: () async {
                      if (selectedImage == null) {
                        debugLog('이미지가 선택되지 않았습니다.');
                        return;
                      }

                      File file = File(selectedImage!.path);
                      final list = await uploadImageAndGetList(file);

                      if(list == null) {
                        debugLog('리스트를 받지 못했습니다.');
                      }
                    }

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



class ImageApplyPage extends StatefulWidget {
  final List<dynamic>? initialItems;

  const ImageApplyPage({super.key, this.initialItems});

  @override
  State<ImageApplyPage> createState() => _ImageApplyPageState();
}

class _ImageApplyPageState extends State<ImageApplyPage> {
  List<Map<String, String>> items = [];
  List<bool> checked = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialItems != null) {
      items = widget.initialItems!.map<Map<String, String>>((e) {
        final map = Map<String, String>.from(e);
        return {
          'id': map['id'] ?? '',
          'title': map['title'] ?? '',
          'date': map['date'] ?? '',
        };
      }).toList();

      checked = List.generate(items.length, (_) => false);
    }
  }

  void updateItemsFromServer(List<dynamic> serverList) {
    setState(() {
      items = serverList.map<Map<String, String>>((e) {
        final map = Map<String, String>.from(e);
        return {
          'id': map['id'] ?? '',
          'title': map['title'] ?? '',
          'date': map['date'] ?? '',
        };
      }).toList();

      checked = List.generate(items.length, (_) => false);
    });
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
                          // 오류 무시 또는 로그 출력 가능
                        }
                      }
                    }
                    Navigator.of(context).pop();
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
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("삭제 확인"),
                                    content: const Text("정말 삭제하시겠습니까?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("취소"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            items.removeAt(index);
                                            checked.removeAt(index);
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("삭제"),
                                      ),
                                    ],
                                  );
                                },
                              );
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
