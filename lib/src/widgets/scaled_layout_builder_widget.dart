import 'package:flutter/material.dart';

typedef ScaledLayoutWidgetBuilder = Widget Function(
    BuildContext, BoxConstraints, Size);

class ScaledLayoutBuilder extends StatelessWidget {
  final ScaledLayoutWidgetBuilder builder;
  final Size toScale;

  const ScaledLayoutBuilder({
    Key? key,
    required this.toScale,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scale = (constraints.maxHeight < constraints.maxWidth)
          // Scale to height
          ? constraints.maxHeight / toScale.height
          // Scale to width
          : constraints.maxWidth / toScale.width;

      final scaled = toScale * scale;

      return SizedBox(
        height: scaled.height,
        width: scaled.width,
        child: builder(context, constraints, scaled),
      );
    });
  }
}
