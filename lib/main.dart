import 'package:flutter/cupertino.dart';

import 'components/triangle.form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Validate your triangle',
      home: MyHomePage(title: 'Validate your triangle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  num _sideA = 0;
  num _sideB = 0;
  num _sideC = 0;

  void setSides(num a, num b, num c) {
    setState(() {
      _sideA = a;
      _sideB = b;
      _sideC = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 75),
                child: const Image(
                  image: AssetImage('assets/images/ruler.png'),
                  height: 200,
                ),
              ),

              const SizedBox(height: 110),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [TriangleForm(onSetSides: setSides)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
