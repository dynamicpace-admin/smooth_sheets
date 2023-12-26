import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:smooth_sheets/src/foundation/sheet_extent.dart';

abstract class SheetActivity extends ChangeNotifier {
  double? _pixels;
  double? get pixels => _pixels;

  SheetExtent? _delegate;
  SheetExtent get delegate {
    assert(
      _delegate != null,
      '$SheetActivity must be initialized with initWith().',
    );
    return _delegate!;
  }

  @mustCallSuper
  void initWith(SheetExtent delegate) {
    assert(
      _delegate == null,
      'initWith() must be called only once.',
    );

    _delegate = delegate;
  }

  @protected
  void correctPixels(double pixels) {
    _pixels = pixels;
  }

  @protected
  void setPixels(double pixels) {
    final oldPixels = _pixels;
    correctPixels(pixels);
    if (_pixels != oldPixels) {
      notifyListeners();
      dispatchExtentUpdateNotification();
    }
  }

  void dispatchExtentUpdateNotification() {
    // TODO: Support notifications.
    // SheetExtentUpdateNotification(
    //   metrics: SheetMetricsSnapshot.from(delegate),
    // ).dispatch(delegate.context.notificationContext);
  }

  void dispatchOverflowNotification(double overflow) {
    // TODO: Support notifications.
    // SheetOverflowNotification(
    //   metrics: SheetMetricsSnapshot.from(delegate),
    //   overflow: overflow,
    // ).dispatch(delegate.context.notificationContext);
  }

  void takeOver(SheetActivity other) {
    if (other.pixels != null) {
      correctPixels(other.pixels!);
    }
  }

  void didChangeContentDimensions() {
    if (pixels != null) {
      // TODO: Animate to the new pixels.
      setPixels(
        delegate.physics
            .adjustPixelsForNewBoundaryConditions(pixels!, delegate.metrics),
      );
    }
  }

  void didChangeViewportDimensions() {/* No-op */}
}

class DrivenSheetActivity extends SheetActivity {
  DrivenSheetActivity({
    required this.from,
    required this.to,
    required this.duration,
    required this.curve,
  }) : assert(duration > Duration.zero);

  final double from;
  final double to;
  final Duration duration;
  final Curve curve;

  late final AnimationController _animation;

  final _completer = Completer<void>();

  Future<void> get done => _completer.future;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);
    _animation = AnimationController.unbounded(
      value: from,
      vsync: delegate.context.vsync,
    )
      ..addListener(onAnimationTick)
      ..animateTo(to, duration: duration, curve: curve)
          // Won't trigger if we dispose 'animation' first.
          .whenComplete(onAnimationEnd);
  }

  @protected
  void onAnimationTick() => setPixels(_animation.value);

  @protected
  void onAnimationEnd() => delegate.goBallistic(0);

  @override
  void dispose() {
    _completer.complete();
    _animation.dispose();
    super.dispose();
  }
}

class BallisticSheetActivity extends SheetActivity {
  BallisticSheetActivity({
    required this.simulation,
  });

  final Simulation simulation;
  late final AnimationController controller;

  @override
  void initWith(SheetExtent delegate) {
    super.initWith(delegate);

    controller = AnimationController.unbounded(vsync: delegate.context.vsync)
      ..addListener(onTick)
      ..animateWith(simulation).whenComplete(onEnd);
  }

  void onTick() {
    setPixels(controller.value);
  }

  void onEnd() {
    delegate.goIdle();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class IdleSheetActivity extends SheetActivity {}
