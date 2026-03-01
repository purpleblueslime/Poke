import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../components/call_api.dart';
import '../components/popup.dart';
import '../components/gallery.dart';
import '../components/functions.dart';

class Friend extends StatefulWidget {
  final dynamic wrappedfrnd;

  const Friend({super.key, this.wrappedfrnd});

  @override
  State<Friend> createState() => _Friend();
}

class _Friend extends State<Friend> {
  late dynamic frnd;
  dynamic loading = true;
  dynamic deleteSpin = false;

  @override
  initState() {
    super.initState();
    frnd = widget.wrappedfrnd;
  }

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;

    okConfirm(context, user) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: Duration(minutes: 1),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ), // No curve, full width
          ),
          content: popUp(context, [
            ClipOval(
              child: ExtendedImage.network(
                imgUrl(frnd['uid']),
                height: 110,
                width: 110,
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
            SizedBox(height: 20),
            Text(
              'You really wanna do this?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(
                  context,
                ).removeCurrentSnackBar(reason: SnackBarClosedReason.remove);

                if (deleteSpin) return;
                setState(() {
                  deleteSpin = true;
                });

                dynamic re = await g(
                  '/friends/unfriend?uid=${frnd['uid']}',
                  usr.token,
                );

                if (re.statusCode != 200) {
                  setState(() {
                    deleteSpin = false;
                  });
                  return;
                }

                setState(() {
                  deleteSpin = false;
                });
                Navigator.of(context).popUntil((route) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return false;
                  }
                  return true;
                });

                await usr.refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
              ),
              child: Text('unfriend', style: TextStyle(fontSize: 19)),
            ),
          ]),
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
              child: Stack(
                children: [
                  Container(
                    height: 470,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('images/ghosts_by_slime.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 90,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipOval(
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: ExtendedImage.network(
                                        imgUrl(frnd['uid']),
                                        fit: BoxFit.cover,
                                        cache: true,
                                        cacheMaxAge: Duration(days: 1),
                                        loadStateChanged: (state) {
                                          if (state.extendedImageLoadState ==
                                              LoadState.completed) {
                                            return null;
                                          } else {
                                            return SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  frnd['streaks'] <= 0
                                      ? SizedBox.shrink()
                                      : Positioned(
                                        bottom: 0,
                                        left: 40,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10,
                                              sigmaY: 10,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                left: 8,
                                                right: 8,
                                                top: 4,
                                                bottom: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'images/mending-heart.svg',
                                                    height: 15,
                                                    width: 15,
                                                  ),
                                                  SizedBox(width: 4),
                                                  ShaderMask(
                                                    shaderCallback:
                                                        (bounds) =>
                                                            LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFFF498B,
                                                                ),
                                                                Colors.white,
                                                                Colors.white,
                                                              ],
                                                            ).createShader(
                                                              Rect.fromLTWH(
                                                                0,
                                                                0,
                                                                bounds.width,
                                                                bounds.height,
                                                              ),
                                                            ),
                                                    blendMode: BlendMode.srcIn,
                                                    child: Text(
                                                      '${comify(frnd['streaks'])} day streak',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            Colors
                                                                .white, // must be set for ShaderMask to work properly
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Text(
                                'You\'ve poked ${frnd['nick']} ${frnd['pokes']} times~',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                'thats about ${((frnd['pokes'] / user['p']) * 100).toInt()}% of your ${comify(user['p'])} pokes!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  okConfirm(context, user);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                child:
                                    deleteSpin
                                        ? LoadingAnimationWidget.waveDots(
                                          color: Colors.white,
                                          size: 25,
                                        )
                                        : Text(
                                          'unfriend',
                                          style: TextStyle(fontSize: 15),
                                        ),
                              ),
                            ],
                          ),
                        ),
                        Gallery(uid: frnd['uid']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).padding.top + 60, // safeBar height
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 25,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context, user);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(0),
                                ),
                                child: SvgPicture.asset(
                                  'images/back.svg',
                                  height: 25,
                                  width: 25,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            Text(
                              frnd['nick'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 50),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
