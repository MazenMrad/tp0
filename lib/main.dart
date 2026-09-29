import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Split Rectangles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplitScreenPage(),
    );
  }
}

class SplitScreenPage extends StatefulWidget {
  const SplitScreenPage({super.key, this.seed});

  final int? seed;

  @override
  State<SplitScreenPage> createState() => _SplitScreenPageState();
}

class _SplitScreenPageState extends State<SplitScreenPage> {
  late final math.Random _random =
      widget.seed == null ? math.Random() : math.Random(widget.seed);

  late Color _rootColor = randomColor(_random);

  int _generation = 0;

  double _gap = 0;

  double _radius = 0;

  double _borderWidth = 0;

  bool _panelOpen = true;

  void _reset() {
    setState(() {
      _generation++;
      _rootColor = randomColor(_random);
    });
  }

  void _pickColor(Color color) {
    setState(() {
      _generation++;
      _rootColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SplitBox(
              key: ValueKey('canvas-$_generation'),
              color: _rootColor,
              random: _random,
              gap: _gap,
              radius: _radius,
              borderWidth: _borderWidth,
            ),
          ),
          Positioned(
            right: 16 + padding.right,
            top: 16 + padding.top,
            bottom: 80 + padding.bottom,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _panelOpen
                    ? _ControlPanel(
                        key: const ValueKey('options-panel'),
                        gap: _gap,
                        radius: _radius,
                        borderWidth: _borderWidth,
                        rootColor: _rootColor,
                        onGapChanged: (v) => setState(() => _gap = v),
                        onRadiusChanged: (v) => setState(() => _radius = v),
                        onBorderWidthChanged: (v) =>
                            setState(() => _borderWidth = v),
                        onColorPicked: _pickColor,
                        onCollapse: () => setState(() => _panelOpen = false),
                      )
                    : IconButton.filledTonal(
                        key: const ValueKey('options-expand'),
                        onPressed: () => setState(() => _panelOpen = true),
                        tooltip: 'Show options',
                        icon: const Icon(Icons.tune),
                      ),
              ),
            ),
          ),
          Positioned(
            right: 16 + padding.right,
            bottom: 16 + padding.bottom,
            child: IconButton.filledTonal(
              onPressed: _reset,
              tooltip: 'New canvas',
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

const double _minSide = 24;

class SplitBox extends StatefulWidget {
  const SplitBox({
    super.key,
    required this.color,
    required this.random,
    this.gap = 0,
    this.radius = 0,
    this.borderWidth = 0,
  });

  final Color color;

  final math.Random random;

  final double gap;

  final double radius;

  final double borderWidth;

  @override
  State<SplitBox> createState() => _SplitBoxState();
}

class _SplitBoxState extends State<SplitBox> {
  Axis? _axis;
  Color? _firstColor;
  Color? _secondColor;

  bool get _isSplit => _axis != null;

  Axis _axisFor(Size size) =>
      size.width >= size.height ? Axis.horizontal : Axis.vertical;

  bool _canSplit(Size size) {
    final longest = math.max(size.width, size.height);
    final shortest = math.min(size.width, size.height);
    return shortest >= _minSide && longest >= 2 * _minSide;
  }

  void _split(Size size) {
    if (_isSplit || !_canSplit(size)) {
      return;
    }
    final first = randomColor(widget.random, base: widget.color);
    setState(() {
      _axis = _axisFor(size);
      _firstColor = first;
      _secondColor = randomColor(widget.random, base: first);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_isSplit) {
          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _split(constraints.biggest),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: widget.borderWidth <= 0
                      ? null
                      : Border.all(color: Colors.black, width: widget.borderWidth),
                ),
              ),
            ),
          );
        }

        final first = SplitBox(
          color: _firstColor!,
          random: widget.random,
          gap: widget.gap,
          radius: widget.radius,
          borderWidth: widget.borderWidth,
        );
        final second = SplitBox(
          color: _secondColor!,
          random: widget.random,
          gap: widget.gap,
          radius: widget.radius,
          borderWidth: widget.borderWidth,
        );
        final spacer = widget.gap <= 0
            ? const SizedBox.shrink()
            : _axis == Axis.horizontal
                ? SizedBox(width: widget.gap)
                : SizedBox(height: widget.gap);
        if (_axis == Axis.horizontal) {
          return Row(
            children: [
              Expanded(child: first),
              spacer,
              Expanded(child: second),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: first),
            spacer,
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

const List<Color> _swatches = [
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
];

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    super.key,
    required this.gap,
    required this.radius,
    required this.borderWidth,
    required this.rootColor,
    required this.onGapChanged,
    required this.onRadiusChanged,
    required this.onBorderWidthChanged,
    required this.onColorPicked,
    required this.onCollapse,
  });

  final double gap;
  final double radius;
  final double borderWidth;
  final Color rootColor;
  final ValueChanged<double> onGapChanged;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onBorderWidthChanged;
  final ValueChanged<Color> onColorPicked;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 32, 12, 8),
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gap: ${gap.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: gap,
                min: 0,
                max: 24,
                divisions: 24,
                label: gap.toStringAsFixed(0),
                onChanged: onGapChanged,
              ),
              Text('Radius: ${radius.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: radius,
                min: 0,
                max: 32,
                divisions: 32,
                label: radius.toStringAsFixed(0),
                onChanged: onRadiusChanged,
              ),
              Text('Border: ${borderWidth.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.labelLarge),
              Slider(
                value: borderWidth,
                min: 0,
                max: 8,
                divisions: 16,
                label: borderWidth.toStringAsFixed(1),
                onChanged: onBorderWidthChanged,
              ),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _swatches)
                    _SwatchDot(
                      color: color,
                      selected: color.toARGB32() == rootColor.toARGB32(),
                      onTap: () => onColorPicked(color),
                    ),
                ],
              ),
            ],
          ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: onCollapse,
              tooltip: 'Hide options',
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.black26,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

Color randomColor(math.Random random, {Color? base}) {
  final hue = base == null
      ? random.nextDouble() * 360
      : (HSVColor.fromColor(base).hue + 90 + random.nextDouble() * 180) % 360;
  return HSVColor.fromAHSV(
    1,
    hue,
    0.45 + random.nextDouble() * 0.45,
    0.70 + random.nextDouble() * 0.30,
  ).toColor();
}
