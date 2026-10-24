import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/scale/app_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeSafeScale', () {
    test('design-frame phone keeps the design size', () {
      expect(computeSafeScale(width: 390, devicePixelRatio: 3), 1.0);
    });

    test('small phone shrinks, but never below 0.9', () {
      expect(computeSafeScale(width: 320, devicePixelRatio: 2), 0.9);
      expect(computeSafeScale(width: 360, devicePixelRatio: 3), 360 / 390);
    });

    test('large sharp phone grows, but never above 1.1', () {
      expect(computeSafeScale(width: 420, devicePixelRatio: 3), 420 / 390);
      expect(computeSafeScale(width: 480, devicePixelRatio: 3), 1.1);
    });

    test('large low-density phone is capped at 1.0 to avoid UI bloat', () {
      expect(computeSafeScale(width: 414, devicePixelRatio: 2.6), 1.0);
      expect(computeSafeScale(width: 370, devicePixelRatio: 2), 370 / 390);
    });

    test('low-density cap wins over the tablet range', () {
      expect(computeSafeScale(width: 768, devicePixelRatio: 2), 1.0);
    });

    test('sharp tablet grows up to 1.2', () {
      expect(computeSafeScale(width: 1024, devicePixelRatio: 3), 1.2);
    });
  });

  group('SafeScaleNum', () {
    testWidgets('returns design sizes on the design frame', (tester) async {
      tester.view.physicalSize = const Size(
        DesignFrame.width * 3,
        DesignFrame.height * 3,
      );
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      late double width;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            initSafeScale(context);
            width = 100.w;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(width, closeTo(100, 0.001));
      expect(16.sp, greaterThan(0));
      expect(48.h, greaterThan(0));
    });
  });
}
