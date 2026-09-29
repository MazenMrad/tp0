import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tp0/main.dart';

/// Puts a rectangular test surface of the given size on screen.
Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MyApp());
}

void main() {
  testWidgets('starts as a single full-screen rectangle', (tester) async {
    await _setSurface(tester, const Size(800, 600));

    expect(find.byType(SplitBox), findsOneWidget);
    expect(tester.getSize(find.byType(SplitBox)), const Size(800, 600));
  });

  testWidgets('landscape rectangle splits along its width', (tester) async {
    await _setSurface(tester, const Size(800, 600));

    await tester.tap(find.byType(SplitBox));
    await tester.pump();

    expect(find.byType(SplitBox), findsNWidgets(3));
    expect(find.byType(Row), findsWidgets);
    expect(tester.getSize(find.byType(SplitBox).at(1)), const Size(400, 600));
    expect(tester.getSize(find.byType(SplitBox).at(2)), const Size(400, 600));
  });

  testWidgets('portrait rectangle splits along its height', (tester) async {
    await _setSurface(tester, const Size(600, 800));

    await tester.tap(find.byType(SplitBox));
    await tester.pump();

    expect(find.byType(SplitBox), findsNWidgets(3));
    expect(find.byType(Column), findsWidgets);
    expect(tester.getSize(find.byType(SplitBox).at(1)), const Size(600, 400));
    expect(tester.getSize(find.byType(SplitBox).at(2)), const Size(600, 400));
  });

  testWidgets('keeps subdividing but never produces slivers', (tester) async {
    await _setSurface(tester, const Size(800, 600));

    // Tap repeatedly at a fixed point away from the reset button; hit-testing
    // always splits whichever cell currently covers that point.
    for (var i = 0; i < 8; i++) {
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
    }

    final boxes = tester.widgetList<SplitBox>(find.byType(SplitBox)).toList();
    // 1 root + 2 children per successful split: every tap must have split.
    expect(boxes.length, 17);

    // boxes[0] is the root (it spans the whole screen). Only the *leaves*
    // (cells with no SplitBox descendants) tile the canvas without overlap.
    var area = 0.0;
    for (final box in boxes.skip(1)) {
      final hasChildren = find
          .descendant(of: find.byWidget(box), matching: find.byType(SplitBox))
          .evaluate()
          .isNotEmpty;
      if (hasChildren) continue;

      final size = tester.getSize(find.byWidget(box));
      final shortest =
          size.width < size.height ? size.width : size.height;
      expect(shortest, greaterThanOrEqualTo(24.0));
      area += size.width * size.height;
    }
    expect(area, closeTo(800 * 600, 1.0));
  });

  testWidgets('refresh button resets back to one rectangle', (tester) async {
    await _setSurface(tester, const Size(800, 600));

    await tester.tap(find.byType(SplitBox));
    await tester.pump();
    expect(find.byType(SplitBox), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(find.byType(SplitBox), findsOneWidget);
    expect(tester.getSize(find.byType(SplitBox)), const Size(800, 600));
  });
}

