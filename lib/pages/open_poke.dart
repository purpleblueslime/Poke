import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:no_screenshot/no_screenshot.dart';
import '../components/call_api.dart';
import '../components/poke_video.dart';
import './friend.dart';

class OpenPoke extends StatefulWidget {
  final dynamic poke;

  const OpenPoke({super.key, this.poke});

  @override
  State<OpenPoke> createState() => _OpenPoke();
}

class _OpenPoke extends State<OpenPoke> {
  late dynamic poke;
  dynamic loading = false;
  dynamic noScreenshot = NoScreenshot.instance;

  offScreenshot() async {
    await noScreenshot.screenshotOff();
  }

  onScreenshot() async {
    await noScreenshot.screenshotOn();
  }

  @override
  initState() {
    super.initState();
    if (!widget.poke['allowSave']) offScreenshot();
    poke = widget.poke;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserPro>(context);

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
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height -
                      120, // 80 is save button and user (20 x 2 spacing)
                  width: double.infinity,
                  child:
                      poke['is'] == 'img'
                          ? ExtendedImage.network(
                            apiUrl(
                              '/poke/open?token=${userProvider.token}&id=${poke['id']}',
                            ),
                            cache: true,
                            fit: BoxFit.cover,
                            loadStateChanged: (state) {
                              if (state.extendedImageLoadState ==
                                  LoadState.completed) {
                                if (poke['allowSave']) return null;

                                Future.delayed(Duration(seconds: 3), () {
                                  Navigator.pop(context);
                                });
                                return null;
                              } else {
                                return SizedBox.shrink();
                              }
                            },
                          )
                          : PokeVideo(
                            url: apiUrl(
                              '/poke/open?token=${userProvider.token}&id=${poke['id']}',
                            ),
                            ghost: poke['allowSave'] ? null : context,
                          ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).padding.top + 60, // appBar height
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
                              Navigator.pop(context);
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
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                            SizedBox(width: 4),
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
            Positioned(
              bottom: 20,
              left: 10,
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      poke['allowSave']
                          ? ElevatedButton(
                            onPressed: () async {
                              if (loading) return;
                              setState(() {
                                loading = true;
                              });

                              dynamic re = await g(
                                '/poke/toggle_save?id=${poke['id']}',
                                userProvider.token,
                              );

                              if (re.statusCode != 200) {
                                setState(() {
                                  loading = false;
                                });
                                return;
                              }

                              await userProvider
                                  .refresh(); // fixes images not showing in gallery

                              setState(() {
                                poke['saved'] = !poke['saved'];
                                loading = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                            ),
                            child: SizedBox(
                              width:
                                  MediaQuery.of(context).size.width - (80 + 30),
                              height: 60,
                              child: Ink(
                                decoration:
                                    poke['saved']
                                        ? BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xff80ffcc),
                                              Color(0xffaafeea),
                                              Colors.tealAccent,
                                            ],
                                            begin: Alignment.bottomRight,
                                            end: Alignment.topLeft,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        )
                                        : BoxDecoration(),
                                child: Center(
                                  child:
                                      !loading
                                          ? Text(
                                            poke['saved']
                                                ? 'Saved to gallery'
                                                : 'Save to gallery',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          )
                                          : LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                ),
                              ),
                            ),
                          )
                          : SizedBox(
                            width:
                                MediaQuery.of(context).size.width - (80 + 30),
                            height: 60,
                          ), // uhh if save not allow
                    ],
                  ),
                  SizedBox(width: 15),
                  GestureDetector(
                    onTap: () async {
                      if (!poke['allowSave']) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Friend(wrappedfrnd: poke['by']),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    onScreenshot(); // do this even if 'allowSave' to avoid bugs and all
    super.dispose();
  }
}
