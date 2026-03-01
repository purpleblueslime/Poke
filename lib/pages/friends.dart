import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../components/nav_bar.dart';
import '../components/call_api.dart';
import './search.dart';

class Friends extends StatefulWidget {
  const Friends({super.key});

  @override
  State<Friends> createState() => _Friends();
}

class _Friends extends State<Friends> {
  dynamic confirmSpin = [];
  dynamic deleteSpin = [];

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;
    List<Widget> widgets = [];

    for (dynamic u in user['requests']) {
      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipOval(
                  child: ExtendedImage.network(
                    imgUrl(u['uid']),
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                    cache: true,
                    cacheMaxAge: Duration(days: 1),
                    loadStateChanged: (state) {
                      if (state.extendedImageLoadState == LoadState.completed) {
                        return null;
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['nick'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (confirmSpin.contains(u['uid'])) return;
                    setState(() {
                      confirmSpin.add(u['uid']);
                    });

                    dynamic re = await g(
                      '/friends/confirm?uid=${u['uid']}',
                      usr.token,
                    );

                    if (re.statusCode != 200) {
                      setState(() {
                        confirmSpin.removeWhere((uid) => uid == u['uid']);
                      });
                      return;
                    }

                    await usr.refresh();
                    setState(() {
                      confirmSpin.removeWhere((uid) => uid == u['uid']);
                    });
                  },
                  child:
                      confirmSpin.contains(u['uid'])
                          ? LoadingAnimationWidget.waveDots(
                            color: Colors.white,
                            size: 25,
                          )
                          : Text(
                            'Confirm',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (deleteSpin.contains(u['uid'])) return;
                    setState(() {
                      deleteSpin.add(u['uid']);
                    });

                    dynamic re = await g(
                      '/friends/delete?uid=${u['uid']}',
                      usr.token,
                    );

                    if (re.statusCode != 200) {
                      setState(() {
                        deleteSpin.removeWhere((uid) => uid == u['uid']);
                      });
                      return;
                    }

                    await usr.refresh();
                    setState(() {
                      deleteSpin.removeWhere((uid) => uid == u['uid']);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child:
                      deleteSpin.contains(u['uid'])
                          ? LoadingAnimationWidget.waveDots(
                            color: Colors.white,
                            size: 25,
                          )
                          : Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.of(context).padding.top +
                      146, // this safeBar + 16
                  bottom: 76, // navBar + 16
                  left: 16,
                  right: 16,
                ),
                child:
                    user['requests'].length == 0
                        ? Column(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                'images/ghost.svg',
                                height: 55,
                                width: 55,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: Text(
                                'New friend requests pop here!',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Wrap(spacing: 10, runSpacing: 10, children: widgets),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top + 120, // navBar + 60
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Friend Requests',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 16, right: 16),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Search(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'images/category_search.svg',
                                  height: 30,
                                  width: 30,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 25),
                                Text(
                                  'Search',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            NavBar(dontOpen: 'friends'),
          ],
        ),
      ),
    );
  }
}
