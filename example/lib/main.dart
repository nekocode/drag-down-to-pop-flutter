import 'package:drag_down_to_pop/drag_down_to_pop.dart';
import 'package:flutter/material.dart';

void main() => runApp(
      MaterialApp(
        home: FirstPage(),
      ),
    );

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Page'),
      ),
      body: Center(
        child: FlatButton(
          child: Text('Next page'),
          textColor: Colors.white,
          color: Colors.blue,
          onPressed: () {
            Navigator.push(
              context,
              ImageViewerPageRoute(builder: (context) => SecondPage()),
            );
          },
        ),
      ),
    );
  }
}

class ImageViewerPageRoute extends MaterialPageRoute {
  ImageViewerPageRoute({required WidgetBuilder builder})
      : super(builder: builder, maintainState: false);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return const DragDownToPopPageTransitionsBuilder()
        .buildTransitions(this, context, animation, secondaryAnimation, child);
  }

  @override
  bool canTransitionFrom(TransitionRoute previousRoute) {
    return false;
  }

  @override
  bool canTransitionTo(TransitionRoute nextRoute) {
    return false;
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        child: Image.network(
          'https://ww4.sinaimg.cn/bmiddle/5c9763c0jw1dg9c1if6bjj.jpg',
        ),
      ),
      onTap: () {
        Navigator.maybePop(context);
      },
    );
  }
}
