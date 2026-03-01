import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import '../user_provider.dart';
import 'package:extended_image/extended_image.dart';
import 'call_api.dart';
import '../pages/me.dart';
import '../pages/friends.dart';
import '../pages/chat.dart';
import '../pages/cam.dart';

class NavBar extends StatefulWidget {
  final dynamic dontOpen;

  const NavBar({super.key, this.dontOpen});

  @override
  State<NavBar> createState() => _NavBar();
}

class _NavBar extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    dynamic user = Provider.of<UserPro>(context).user;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 66, // navBar height 66
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    if (widget.dontOpen == 'cam') return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Cam()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero, // to avoid extra space
                  ),
                  child: SvgPicture.asset(
                    'images/camera.svg',
                    height: 35,
                    width: 35,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    alignment: Alignment.center,
                  ),
                ),
                Stack(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (widget.dontOpen == 'chat') return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Chat()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero, // to avoid extra space
                      ),
                      child: SvgPicture.asset(
                        'images/chats.svg',
                        height: 35,
                        width: 35,
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        alignment: Alignment.center,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child:
                          user['pokes'].any((pke) => pke['opened'] == false)
                              ? Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Color(0xff7ceece),
                                  shape: BoxShape.circle,
                                ),
                              )
                              : SizedBox.shrink(),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (widget.dontOpen == 'friends') return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Friends()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero, // to avoid extra space
                      ),
                      child: SvgPicture.asset(
                        'images/search.svg',
                        height: 35,
                        width: 35,
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        alignment: Alignment.center,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child:
                          user['requests'].length == 0
                              ? SizedBox.shrink()
                              : Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Color(0xff7ceece),
                                  shape: BoxShape.circle,
                                ),
                              ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (widget.dontOpen == 'me') return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Me()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero, // to avoid extra space
                  ),
                  child: ClipOval(
                    child: ExtendedImage.network(
                      imgUrl(user['uid']),
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      cache: true,
                      cacheMaxAge: Duration(days: 1),
                      loadStateChanged: (state) {
                        if (state.extendedImageLoadState ==
                            LoadState.completed) {
                          return null;
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
