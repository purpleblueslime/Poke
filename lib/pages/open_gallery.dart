import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../components/call_api.dart';
import '../components/functions.dart';
import '../components/popup.dart';
import '../components/poke_video.dart';
import './friend.dart';
import './me.dart';

class OpenGallery extends StatefulWidget {
  final dynamic poke;
  final dynamic pokes;

  const OpenGallery({super.key, this.poke, this.pokes});

  @override
  State<OpenGallery> createState() => _OpenGallery();
}

class _OpenGallery extends State<OpenGallery> {
  late dynamic poke;
  late dynamic pokes;
  dynamic offsetx = 0.0;
  dynamic ani = true;
  dynamic downloading = false;
  dynamic loading = false;

  @override
  initState() {
    super.initState();
    poke = widget.poke;
    pokes = widget.pokes;
  }

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;

    dynamic nice = niceDate(poke['createdAt']);

    List<Widget> tos = [];

    for (dynamic u in poke['to']) {
      tos.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        u['uid'] == user['uid'] ? Me() : Friend(wrappedfrnd: u),
              ),
            );
          },
          child: ClipOval(
            child: ExtendedImage.network(
              imgUrl(u['uid']),
              width: 80,
              height: 80,
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
        ),
      );
      tos.add(SizedBox(width: 15));
    }

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
            SizedBox(
              width: 160, // w 1080 in ':'
              height: 284.44, // h 1920 in ':'
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child:
                    poke['is'] == 'img'
                        ? ExtendedImage.network(
                          apiUrl(
                            '/poke/saved?token=${usr.token}&id=${poke['id']}',
                          ),
                          cache: true,
                          fit: BoxFit.cover,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.completed) {
                              return null;
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        )
                        : PokeVideo(
                          url: apiUrl(
                            '/poke/saved?token=${usr.token}&id=${poke['id']}',
                          ),
                          thumbnail: true,
                        ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'You really wanna delete this poke?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (loading) return;
                setState(() {
                  loading = true;
                });
                ScaffoldMessenger.of(
                  context,
                ).removeCurrentSnackBar(reason: SnackBarClosedReason.remove);

                dynamic re = await g(
                  '/poke/saved/delete?id=${poke['id']}',
                  usr.token,
                );

                if (re.statusCode != 200) {
                  setState(() {
                    loading = false;
                  });
                  return;
                }
                setState(() {
                  loading = false;
                });
                Navigator.pop(context);

                usr.refresh();
                return;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
              ),
              child: Text('delete', style: TextStyle(fontSize: 19)),
            ),
          ]),
        ),
      );
    }

    dynamic onSwipeLeft() async {
      setState(() => offsetx = -1.5);
      await Future.delayed(Duration(milliseconds: 100));

      dynamic i = pokes.indexWhere((p) => p['id'] == poke['id']);
      if (i != pokes.length - 1) {
        setState(() {
          poke = pokes[i + 1];
          ani = false;
          offsetx = 1.5;
        });
        await Future.delayed(Duration(milliseconds: 100));
      }

      setState(() {
        ani = true;
        offsetx = 0.0;
      });
    }

    dynamic onSwipeRight() async {
      setState(() => offsetx = 1.5);
      await Future.delayed(Duration(milliseconds: 100));

      dynamic i = pokes.indexWhere((p) => p['id'] == poke['id']);
      if (i != 0) {
        setState(() {
          poke = pokes[i - 1];
          ani = false;
          offsetx = -1.5;
        });
        await Future.delayed(Duration(milliseconds: 100));
      }

      setState(() {
        ani = true;
        offsetx = 0.0;
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                child: GestureDetector(
                  onHorizontalDragEnd: (e) {
                    dynamic delta = e.velocity.pixelsPerSecond;
                    if (delta.dx > 0) {
                      onSwipeRight();
                    } else if (delta.dx < 0) {
                      onSwipeLeft();
                    }
                  },
                  child: SizedBox(
                    height:
                        MediaQuery.of(context).size.height -
                        120, // 80 is saved button and users (20 x 2 spacing)
                    width: double.infinity,
                    child: AnimatedSlide(
                      offset: Offset(offsetx, 0),
                      duration:
                          ani
                              ? Duration(milliseconds: 200)
                              : Duration(seconds: 0),
                      curve: Curves.easeOut,
                      child:
                          poke['is'] == 'img'
                              ? ExtendedImage.network(
                                apiUrl(
                                  '/poke/saved?token=${usr.token}&id=${poke['id']}',
                                ),
                                cache: true,
                                fit: BoxFit.cover,
                                loadStateChanged: (state) {
                                  if (state.extendedImageLoadState ==
                                      LoadState.completed) {
                                    return null;
                                  } else {
                                    return SizedBox.shrink();
                                  }
                                },
                              )
                              : PokeVideo(
                                key: ValueKey(
                                  poke['id'],
                                ), // uhhh need this otherwise it wont change vid on swipe
                                url: apiUrl(
                                  '/poke/saved?token=${usr.token}&id=${poke['id']}',
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120 + 20, // 20 up the image/v
              left: 20, // 20 space in left
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nice['time'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    nice['day'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
                decoration: BoxDecoration(color: Colors.transparent),
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
                        Row(
                          children: [
                            poke['geo'] == null
                                ? SizedBox.shrink()
                                : Text(
                                  poke['geo'],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xff80ffcc),
                                  ),
                                ),
                            SizedBox(width: 2.5),
                            SvgPicture.asset(
                              poke['geo'] != null
                                  ? 'images/near_me.svg'
                                  : 'images/near_me_off.svg',
                              height: 25,
                              width: 25,
                              colorFilter: ColorFilter.mode(
                                poke['geo'] == null
                                    ? Colors.white
                                    : Color(0xff80ffcc),
                                BlendMode.srcIn,
                              ),
                              alignment: Alignment.center,
                            ),
                          ],
                        ),
                        SizedBox(width: 50),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                okConfirm(context, user);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xffff495e),
                                      Color(0xfffe5e93),
                                      Color(0xffff6d77),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child:
                                      loading
                                          ? Center(
                                            child:
                                                LoadingAnimationWidget.waveDots(
                                                  color: Colors.white,
                                                  size: 35,
                                                ),
                                          )
                                          : Center(
                                            child: SvgPicture.asset(
                                              'images/close.svg',
                                              width: 50,
                                              height: 50,
                                              colorFilter: ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 15),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        poke['by']['uid'] == user['uid']
                                            ? Me()
                                            : Friend(wrappedfrnd: poke['by']),
                              ),
                            );
                          },
                          child: ClipOval(
                            child: ExtendedImage.network(
                              imgUrl(poke['by']['uid']),
                              width: 80,
                              height: 80,
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
                        SizedBox(width: 15),
                        ...tos,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
