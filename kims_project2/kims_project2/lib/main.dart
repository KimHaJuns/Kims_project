import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

typedef OnDaySelected = void Function(
  DateTime selectedDay, DateTime focusedDay
);

class Event{
  String title;

  Event(this.title);
}

Map<DateTime, List<Event>> events = {
  DateTime.utc(2025,7,13) : [ Event('title'), Event('title2') ],
  DateTime.utc(2025,7,14) : [ Event('title3') ],
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

final List<Event> Function(DateTime day) eventLoader = getEventsForDay;

class _CalendarPageState extends State<CalendarPage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('달력앱')),
      body: TableCalendar(
        calendarStyle: CalendarStyle(
          markerSize: 10.0,
          markerDecoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle
          ),
          defaultTextStyle: TextStyle(color: Colors.grey),
          weekendTextStyle: TextStyle(color: Colors.red),
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black,width: 1)
          ),
          todayTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black
          )
        ),
        locale: 'ko_KR',
        headerStyle: 
          HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true),
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
        onDaySelected: (DateTime selectedDay, DateTime focusedDay){
          setState(() {
            this.selectedDay = selectedDay;
            this.focusedDay = focusedDay;
          });
        },
        selectedDayPredicate: (DateTime day){
          return isSameDay(selectedDay, day);
        }
      ),
    );
  }
}
