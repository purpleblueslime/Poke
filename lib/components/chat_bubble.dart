import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final dynamic left;

  const ChatBubble({super.key, required this.child, this.left = false});

  @override
  Widget build(BuildContext context) {
    dynamic bubbleColor = Color(0xff007aff);

    return Column(
      crossAxisAlignment:
          left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.only(left: 16, top: 10, right: 16, bottom: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: child,
        ),

        // tail :p
        CustomPaint(
          size: Size(20, 12),
          painter: _TrianglePainter(bubbleColor, left),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final dynamic left;

  _TrianglePainter(this.color, this.left);

  @override
  void paint(Canvas canvas, Size size) {
    dynamic paint = Paint()..color = color;

    dynamic path = Path();

    if (left) {
      path.moveTo(size.width, -4.0); // start lil up to overlap bubble corner

      path.lineTo(6.0, size.height * 0.7);

      // round tip
      path.quadraticBezierTo(0.0, size.height, 6.0, size.height * 0.3);

      path.lineTo(8.0, -4.0);
    } else {
      path.moveTo(0.0, -4.0); // same ^

      path.lineTo(size.width - 6.0, size.height * 0.7);

      // round tip
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - 6.0,
        size.height * 0.3,
      );

      path.lineTo(size.width - 8.0, -4.0);
    }

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter x) => false; // never repaint ??
}
