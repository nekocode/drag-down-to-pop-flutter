import 'package:drag_down_to_pop/drag_down_to_pop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test page transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return DragDownToPopPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? '1' : '2';
              return Center(child: Text('Page $pageNumber'));
            },
          );
        },
      ),
    );

    final Offset widget1InitialTopLeft = tester.getTopLeft(find.text('Page 1'));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    Offset widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    Offset widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 isn't moving.
    expect(widget1TransientTopLeft.dx, equals(widget1InitialTopLeft.dx));
    expect(widget1TransientTopLeft.dy, equals(widget1InitialTopLeft.dy));
    // Page 2 is moving vertically only, and is coming in from the bottom.
    expect(widget2TopLeft.dx, equals(widget1InitialTopLeft.dx));
    expect(widget2TopLeft.dy, greaterThan(widget1InitialTopLeft.dy));

    await tester.pumpAndSettle();

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    widget1TransientTopLeft = tester.getTopLeft(find.text('Page 1'));
    widget2TopLeft = tester.getTopLeft(find.text('Page 2'));

    // Page 1 isn't moving.
    expect(widget1TransientTopLeft.dx, equals(widget1InitialTopLeft.dx));
    expect(widget1TransientTopLeft.dy, equals(widget1InitialTopLeft.dy));
    // Page 2 is moving vertically only, and is leaving towards the bottom.
    expect(widget2TopLeft.dx, equals(widget1InitialTopLeft.dx));
    expect(widget2TopLeft.dy, greaterThan(widget1InitialTopLeft.dy));

    await tester.pumpAndSettle();

    expect(find.text('Page 1'), isOnstage);
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('test dragging-down work', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return DragDownToPopPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? '1' : '2';
              return Center(child: Text('Page $pageNumber'));
            },
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Page 2 covers page 1.
    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    Offset widget2InitialTopLeft = tester.getTopLeft(find.text('Page 2'));

    // Drag from the middle to the up.
    TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
    await gesture.moveBy(const Offset(0.0, -200.0));
    await tester.pump();

    // Page 2 isn't moving.
    Offset widget2TransientTopLeft = tester.getTopLeft(find.text('Page 2'));
    expect(widget2TransientTopLeft.dx, equals(widget2InitialTopLeft.dx));
    expect(widget2TransientTopLeft.dy, equals(widget2InitialTopLeft.dy));

    await gesture.up();

    // Drag from the middle to the bottom.
    gesture = await tester.startGesture(const Offset(200.0, 200.0));
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pump();

    // Page 2 is moving vertically only, and is leaving towards the bottom.
    widget2TransientTopLeft = tester.getTopLeft(find.text('Page 2'));
    expect(widget2TransientTopLeft.dx, equals(widget2InitialTopLeft.dx));
    expect(widget2TransientTopLeft.dy, greaterThan(widget2InitialTopLeft.dy));

    await gesture.up();
  });

  testWidgets('test drag down then drop back to the starting point works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        onGenerateRoute: (RouteSettings settings) {
          return DragDownToPopPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              final String pageNumber = settings.name == '/' ? '1' : '2';
              return Center(child: Text('Page $pageNumber'));
            },
          );
        },
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Page 1'), findsNothing);
    expect(find.text('Page 2'), isOnstage);

    Offset widget2InitialTopLeft = tester.getTopLeft(find.text('Page 2'));

    TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
    await gesture.moveBy(const Offset(0.0, 10.0));
    await gesture.cancel();
    // Wait for animation end.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Page 2 drops back to the starting point.
    Offset widget2TransientTopLeft = tester.getTopLeft(find.text('Page 2'));
    expect(widget2TransientTopLeft.dx, equals(widget2InitialTopLeft.dx));
    expect(widget2TransientTopLeft.dy, equals(widget2InitialTopLeft.dy));
  });
}

class DragDownToPopPageRoute extends CupertinoPageRoute<void> {
  DragDownToPopPageRoute(
      {@required WidgetBuilder builder, RouteSettings settings})
      : super(builder: builder, settings: settings, maintainState: false);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return const DragDownToPopPageTransitionsBuilder()
        .buildTransitions(this, context, animation, secondaryAnimation, child);
  }
}
