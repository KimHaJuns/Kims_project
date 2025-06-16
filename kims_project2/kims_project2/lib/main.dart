import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

typedef OnDaySelected = void Function(DateTime selectedDay, DateTime focusedDay);

class Event {
  String title;

  Event(this.title);
}

Map<DateTime, List<Event>> events = {
  DateTime.utc(2025, 7, 13): [Event('title'), Event('title2')],
  DateTime.utc(2025, 7, 14): [Event('title3')],
};

List<Event> getEventsForDay(DateTime day) {
  return events[day] ?? [];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '달력앱',
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CalendarPage(), // 여기를 MyAppStatefulPage()로 바꾸면 이미지 기능 테스트 가능
      debugShowCheckedModeBanner: false,
    );
  }
}

void addDialog(context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        color: const Color(0xFF737373),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
        ),
      );
    },
  );
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

final List<Event> Function(DateTime day) eventLoader = getEventsForDay;

class _CalendarPageState extends State<CalendarPage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  int _lastPressedTimestamp = 0;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('달력앱')),
    body: Column(
    children: [
    ElevatedButton.icon(
       onPressed: () {
         pickAndShowImage(context); // <- 이렇게 람다로 감싸야 동작합니다!
      },
      icon: const Icon(Icons.add),
      label: const Text("파일 추가"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
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
            onPageChanged: (focusedDay) {
              setState(() {
                this.focusedDay = focusedDay;
              });
            },
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

              if (currentTimestamp - _lastPressedTimestamp < 500 &&
                  isSameDay(this.selectedDay, selectedDay)) {
                final eventsForDay = getEventsForDay(selectedDay);
                final formattedDate =
                    "${selectedDay.year}년 ${selectedDay.month}월 ${selectedDay.day}일";

                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      width: 600,
                      height: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...eventsForDay.map((event) => Text("• ${event.title}")),
                          if (eventsForDay.isEmpty)
                            const Text("등록된 일정이 없습니다."),
                        ],
                      ),
                    );
                  },
                );
                _lastPressedTimestamp = 0;
              } else {
                _lastPressedTimestamp = currentTimestamp;
                setState(() {
                  this.selectedDay = selectedDay;
                  this.focusedDay = focusedDay;
                });
              }
            },
            selectedDayPredicate: (DateTime day) {
              return isSameDay(selectedDay, day);
            },
          ),
        ),
      ],
    ),
  );
}

}

Future<void> pickAndShowImage(BuildContext context) async {
  XFile? selectedImage;
  String status = '이미지를 선택해주세요';
  final ImagePicker picker = ImagePicker();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                if (selectedImage != null)
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: FileImage(File(selectedImage!.path)),
                  ),
                const SizedBox(height: 30),
                Text(
                  status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  onPressed: () async {
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                        status = '이미지가 선택되었습니다.';
                      });
                    } else {
                      setState(() {
                        status = '아무것도 선택하지 않았습니다.';
                      });
                    }
                  },
                  child: const Text('이미지 선택'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

