import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PokeError extends StatefulWidget {
  final dynamic note;

  const PokeError({super.key, this.note});

  @override
  State<PokeError> createState() => _PokeErrorState();
}

class _PokeErrorState extends State<PokeError> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 20,
      right: 20,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xffff495e),
                          Color(0xfffe5e93),
                          Color(0xffff6d77),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'images/close-small.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.note,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
