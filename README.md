# drag_down_to_pop

[![build status](https://api.travis-ci.com/nekocode/drag-down-to-pop-flutter.svg)](https://travis-ci.com/nekocode/drag-down-to-pop-flutter)

A page transition which supports drag-down-to-pop gesture. The main source code is copied from the [cupertino/route.dart](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/cupertino/route.dart) in Flutter SDK with some modification.

<kbd><img border="1" src="https://github.com/nekocode/drag-down-to-pop-flutter/blob/master/image/preview.gif?raw=true"></img></kbd>

## Simplest Usage

Create a new `PageRoute` to use this page transiaction.

```dart
import 'package:drag_down_to_pop/drag_down_to_pop.dart';

class ImageViewerPageRoute extends MaterialPageRoute {
  ImageViewerPageRoute({@required WidgetBuilder builder})
      : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return const DragDownToPopPageTransitionsBuilder()
        .buildTransitions(this, context, animation, secondaryAnimation, child);
  }
}

// Push to a new page using ImageViewerPageRoute
Navigator.push(
  context,
  ImageViewerPageRoute(builder: (context) => ImageViewerPage()),
);
```
