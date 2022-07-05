import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';

class InteractiveImage extends StatefulWidget {
  InteractiveImage({Key? key, required this.image}) : super(key: key);

  final Image image;

  @override
  _InteractiveImageState createState() => new _InteractiveImageState();
}

class _InteractiveImageState extends State<InteractiveImage> {
  _InteractiveImageState();

  double _scale = 1.0;
  double? _previousScale;

  @override
  Widget build(BuildContext context) {
    setState(() => print("STATE SET\n"));
    return new GestureDetector(
      onScaleStart: (ScaleStartDetails details) {
        print(details);
        // Does this need to go into setState, too?
        // We are only saving the scale from before the zooming started
        // for later - this does not affect the rendering...
        _previousScale = _scale;
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        print(details);
        setState(() => _scale = _previousScale! * details.scale);
      },
      onScaleEnd: (ScaleEndDetails details) {
        print(details);
        // See comment above
        _previousScale = null;
      },
      child: new Transform(
        transform: new Matrix4.diagonal3(new Vector3(_scale, _scale, _scale)),
        alignment: FractionalOffset.center,
        child: widget.image,
      ),
    );
  }
}