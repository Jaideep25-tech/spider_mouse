import 'package:flutter/material.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({
    super.key,
    required this.onThemeChanged,
  });

  final VoidCallback onThemeChanged;

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resteCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Spidermouse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4),
            onPressed: widget.onThemeChanged,
            mouseCursor: SystemMouseCursors.none,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _resteCounter,
              style: ButtonStyle(
                mouseCursor: MaterialStateProperty.all(SystemMouseCursors.none),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        // tooltip: 'Increment',
        mouseCursor: SystemMouseCursors.none,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
