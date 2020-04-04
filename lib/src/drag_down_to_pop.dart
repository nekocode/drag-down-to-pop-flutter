/// Copyright 2020 nekocode.cn@gmail.com
/// Copyright 2017 The Chromium Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style license that can be
/// found in the LICENSE file.
/// This file is copied from flutter sdk with some modifications.
/// See [CupertinoPageRoute]

import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const double _kMinFlingVelocity = 1.0; // Screen heights per second.
const int _kMaxDroppedSwipePageForwardAnimationTime = 800; // Milliseconds.
const int _kMaxPageBackAnimationTime = 300; // Milliseconds.

class DragDownToPopPageTransitionsBuilder extends PageTransitionsBuilder {
  const DragDownToPopPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: _isPopGestureInProgress(route),
      child: _BackGestureDetector<T>(
        enabledCallback: () => _isPopGestureEnabled<T>(route),
        onStartPopGesture: () => _startPopGesture<T>(route),
        child: child,
      ),
    );
  }

  static bool _isPopGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator.userGestureInProgress;
  }

  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    if (route.isFirst) return false;
    if (route.willHandlePopInternally) return false;
    // ignore: invalid_use_of_protected_member
    if (route.hasScopedWillPopCallback) return false;
    if (route.fullscreenDialog) return false;
    if (route.animation.status != AnimationStatus.completed) return false;
    if (route.secondaryAnimation.status != AnimationStatus.dismissed)
      return false;
    if (_isPopGestureInProgress(route)) return false;

    return true;
  }

  static _BackGestureController<T> _startPopGesture<T>(PageRoute<T> route) {
    assert(_isPopGestureEnabled(route));

    return _BackGestureController<T>(
      navigator: route.navigator,
      // ignore: invalid_use_of_protected_member
      controller: route.controller,
    );
  }
}

class _PageTransition extends StatelessWidget {
  _PageTransition({
    Key key,
    @required Animation<double> primaryRouteAnimation,
    @required Animation<double> secondaryRouteAnimation,
    @required this.child,
    @required bool linearTransition,
  })  : assert(linearTransition != null),
        _primaryAnimation1 = (linearTransition
                ? primaryRouteAnimation
                : CurvedAnimation(
                    parent: primaryRouteAnimation,
                    curve: Curves.linearToEaseOut,
                  ))
            .drive(Tween<double>(
          begin: 0.0,
          end: 1.0,
        )),
        _primaryAnimation2 = (linearTransition
                ? primaryRouteAnimation
                : CurvedAnimation(
                    parent: primaryRouteAnimation,
                    curve: Curves.linearToEaseOut,
                  ))
            .drive(Tween<Offset>(
          begin: Offset(0.0, 0.1),
          end: Offset(0.0, 0.0),
        )),
        super(key: key);

  final Animation<double> _primaryAnimation1;
  final Animation<Offset> _primaryAnimation2;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return FadeTransition(
      opacity: _primaryAnimation1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SlideTransition(
          position: _primaryAnimation2,
          child: child,
        ),
      ),
    );
  }
}

class _BackGestureDetector<T> extends StatefulWidget {
  const _BackGestureDetector({
    Key key,
    @required this.enabledCallback,
    @required this.onStartPopGesture,
    @required this.child,
  })  : assert(enabledCallback != null),
        assert(onStartPopGesture != null),
        assert(child != null),
        super(key: key);

  final Widget child;

  final ValueGetter<bool> enabledCallback;

  final ValueGetter<_BackGestureController<T>> onStartPopGesture;

  @override
  _BackGestureDetectorState<T> createState() => _BackGestureDetectorState<T>();
}

class _BackGestureDetectorState<T> extends State<_BackGestureDetector<T>> {
  _BackGestureController<T> _backGestureController;
  VerticalDragGestureRecognizer _recognizer;
  int _lastPointer = -1;
  bool _rejected = false;

  @override
  void initState() {
    super.initState();
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController.dragUpdate(
        _convertToLogical(details.primaryDelta / (context.size.height / 6)));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    if (!_rejected) {
      _backGestureController.dragEnd(_convertToLogical(
          details.velocity.pixelsPerSecond.dy / context.size.height));
    } else {
      _backGestureController.dragEnd(0.0, cancel: true);
    }
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0, cancel: true);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_lastPointer >= 0) {
      // If another pointer is down, reject this gesture
      _rejected = true;
      _recognizer.rejectGesture(_lastPointer);
      _lastPointer = -1;
    } else if (widget.enabledCallback() && _lastPointer < 0) {
      _rejected = false;
      _lastPointer = event.pointer;
      _recognizer.addPointer(event);
    }
  }

  void _handlePointerCancel(PointerEvent event) {
    if (event.pointer == _lastPointer) {
      _lastPointer = -1;
    }
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          end: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerCancel,
            onPointerCancel: _handlePointerCancel,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class _BackGestureController<T> {
  _BackGestureController({
    @required this.navigator,
    @required this.controller,
  })  : assert(navigator != null),
        assert(controller != null) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity, {bool cancel = false}) {
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    bool animateForward;

    if (velocity.abs() >= _kMinFlingVelocity || cancel)
      animateForward = velocity <= 0;
    else
      animateForward = controller.value > 0.5;

    if (animateForward) {
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(
                _kMaxDroppedSwipePageForwardAnimationTime, 0, controller.value)
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationCurve);
    } else {
      navigator.pop();

      if (controller.isAnimating) {
        final int droppedPageBackAnimationTime = lerpDouble(
                0, _kMaxDroppedSwipePageForwardAnimationTime, controller.value)
            .floor();
        controller.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationCurve);
      }
    }

    if (controller.isAnimating) {
      AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
