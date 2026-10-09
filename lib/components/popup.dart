import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/svg.dart';

popUp(ctx, widget) {
  return SizedBox(
    height: 550,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'images/down.svg',
                height: 50,
                width: 50,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                alignment: Alignment.center,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [...widget],
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    ),
  );
}
