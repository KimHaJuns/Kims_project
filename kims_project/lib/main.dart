import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://image.utoimage.com/preview/cp872722/2022/12/202212008462_500.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                Text.rich(
                  TextSpan(
                    text: '당신이',
                    style: TextStyle(fontSize: 36, color: Colors.red),
                    children: [
                      TextSpan(
                        text: '버튼을',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      TextSpan(
                        text: '누른 횟수',
                        style: TextStyle(fontSize: 36, color: Colors.green),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '$_counter',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Row(
              children: [
                FloatingActionButton(
                  heroTag: 'minus',
                  onPressed: () {
                    setState(() {
                      _counter--;
                    });
                  },
                  child: const Icon(Icons.remove, size: 30),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'plus',
                  onPressed: _incrementCounter,
                  child: const Icon(Icons.add, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  } // ← 이 중괄호는 build() 함수 닫는 중괄호
} // ← 이 중괄호는 클래스 닫는 중괄호
