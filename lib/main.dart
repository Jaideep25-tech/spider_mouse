import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive/rive.dart';
import 'package:spider_mouse/spider_controller.dart';
import 'package:spider_mouse/ui_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _switchTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spider Mouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple,
        ),
      ),
      themeMode: _themeMode,
      home: SpiderMouse(
        child: CounterPage(
          onThemeChanged: _switchTheme,
        ),
      ),
    );
  }
}

class SpiderMouse extends StatefulWidget {
  const SpiderMouse({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  State<SpiderMouse> createState() => _SpiderMouseState();
}

class _SpiderMouseState extends State<SpiderMouse> {
  late Ticker ticker;

  final Size _cursorSize = const Size(125, 125);

  late final Artboard _artboard;
  late final StateMachineController _stateMachineController;

  late final SpiderController _spider;

  final _indicatorPainter = IndicatorPainter();

  var _previuosDuration = Duration.zero;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    ticker.stop();
    ticker.dispose();
    _stateMachineController.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    ticker = Ticker(_onTick);
    await _setupRiveFile();
    _spider = SpiderController(_stateMachineController);
    ticker.start();
    setState(() {
      _isLoading = false;
    });
  }

  void _onTick(Duration elapsed) {
    _spider.update((elapsed.inMicroseconds.toDouble() -
            _previuosDuration.inMicroseconds.toDouble()) /
        1000000.0);
    _previuosDuration = elapsed;
    setState(() {});
  }

  Future<void> _setupRiveFile() async {
    // Load file
    final file = await RiveFile.asset('assets/spider.riv');

    // Get artboard
    final artboard = file.artboardByName('Spider');
    if (artboard == null) {
      throw Exception('Failed to load artboard');
    }
    _artboard = artboard.instance();

    // Get State Machine controller and attach to artboard
    final controller =
        StateMachineController.fromArtboard(_artboard, 'spider-machine');
    if (controller == null) {
      throw Exception('Failed to load state machine');
    }
    _stateMachineController = controller;
    _artboard.addController(_stateMachineController);
  }

  void _setMousePosition(Offset pos) {
    _indicatorPainter.position = pos;
    _spider.targetPosition = pos;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final pointerOffset = _cursorSize.height / 5;
    final dxPointer = _spider.dx -
        (_cursorSize.width / 2) -
        (pointerOffset * sin(_spider.rotation));
    final dyPointer = _spider.dy -
        (_cursorSize.height / 2) +
        (pointerOffset * cos(_spider.rotation));

    final transform = Matrix4.identity()
      ..translate(
        dxPointer,
        dyPointer,
      )
      ..rotateZ(_spider.rotation);

    return Listener(
      onPointerMove: (event) => _setMousePosition(event.position),
      onPointerHover: (event) => _setMousePosition(event.position),
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          _spider.rightClick();
        } else {
          _spider.leftClick();
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        child: Stack(
          children: [
            RepaintBoundary(child: widget.child),
            IgnorePointer(
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: SizedBox(
                  width: _cursorSize.width,
                  height: _cursorSize.height,
                  child: Rive(
                    artboard: _artboard,
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _indicatorPainter,
            ),
          ],
        ),
      ),
    );
  }
}

class IndicatorPainter extends CustomPainter {
  Offset position = Offset.zero;

  final _indicatorPaint = Paint()
    ..color = Colors.black12
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(position, 5, _indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
