import 'package:flutter/material.dart';
import 'dart:ui';

class SafeBar extends StatefulWidget {
  final dynamic title;

  const SafeBar({super.key, this.title});

  @override
  State<SafeBar> createState() => _SafeBar();
}

class _SafeBar extends State<SafeBar> {
  late dynamic title;

  @override
  initState() {
    super.initState();
    title = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height:
            MediaQuery.of(context).padding.top +
            60, // safebar height 60 + dynamic
        decoration: BoxDecoration(color: Colors.black.withAlpha(200)),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
