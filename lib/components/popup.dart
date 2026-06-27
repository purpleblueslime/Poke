import 'package:flutter/material.dart';
import 'dart:ui';

popUp(ctx, widget) {
  return SizedBox(
    height: 450,
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(240),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [...widget],
          ),
        ),
      ),
    ),
  );
}
