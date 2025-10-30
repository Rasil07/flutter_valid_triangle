import 'package:flutter/cupertino.dart';

import 'components/triangle.form.dart';
import 'components/resultCard/triangle.result.card.dart';

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

  Future<void> setSides(num a, num b, num c) async {
    setState(() {
      _sideA = a;
      _sideB = b;
      _sideC = c;
    });

    // Classify, then open the correct UI.
    final res = TriangleClassifier.classify(a, b, c);
    if (res.type == TriangleType.invalid ||
        res.type == TriangleType.degenerate) {
      // Show a quick Cupertino alert for non-valid
      // (You asked to show the card if it's a valid triangle.)
      // If you want to always show the card, remove this block.
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(res.title),
          content: Text(res.definition),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Valid triangle → show the hover card.
    await showTriangleResultModal(context, a: a, b: b, c: c);
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
