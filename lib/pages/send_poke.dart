import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import '../components/call_api.dart';
import '../components/poke_video.dart';
import './chat.dart';

class SendPoke extends StatefulWidget {
  final XFile file;
  final dynamic whatis;

  const SendPoke({super.key, required this.file, required this.whatis});

  @override
  State<SendPoke> createState() => _SendPoke();
}

class _SendPoke extends State<SendPoke> {
  ScrollController ani = ScrollController();
  late XFile file;
  late dynamic whatis;
  Set<dynamic> uids = {};
  late dynamic users;
  bool loading = false;
  bool downloaded = false;
  bool sending = false;
  bool allowSave = true;
  bool all = false;

  @override
  void initState() {
    super.initState();
    file = widget.file;
    whatis = widget.whatis;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 1), () {
        ani.animateTo(
          MediaQuery.of(context).size.height - 120,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  Future<dynamic> gimmeLocation(p) async {
    if (!p.options['isGeo']) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        p.setOptions({'isGeo': false});
        return null;
      }
    }

    bool noGPS = await Geolocator.isLocationServiceEnabled();
    if (!noGPS) {
      // if user dont have gps on for some reason or its not working
      p.setOptions({'isGeo': false});
      return null;
    }
    Position pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isEmpty) return null;

      Placemark place = placemarks[0];

      dynamic result = [
        place.name,
        place.subLocality,
        place.locality,
        place.country,
      ].firstWhere((location) {
        if (location == null) return false;

        // remove extra whitespaces
        dynamic loc = location.trim();

        if (loc.isEmpty) return false;

        // if shorter than 3 characters (too short to be a real place)
        if (loc.length < 3) return false;

        // if contain only numbers (like '12345')
        if (!RegExp(r'[^\d]').hasMatch(loc)) return false;

        // if contain no letters (to avoid gibberish or symbols only)
        if (!RegExp(r'[a-zA-Z]').hasMatch(loc)) return false;

        // plus codes like '9R6X+48W'
        if (RegExp(r'^[A-Z0-9]{4,7}\+[A-Z0-9]{2,3}$').hasMatch(loc)) {
          return false;
        }

        // if look like latitude and longitude coords
        if (RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$').hasMatch(loc)) {
          return false;
        }

        // blob with no space (like, 'ABCD2739' or 'X9Y88' or 'RP10')
        if (RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$').hasMatch(loc)) {
          return false;
        }

        // sec names (like, 'Sector 62', 'Sec-18A')
        if (RegExp(
          r'\b(sec|sector)[\s\-]*\d+[a-zA-Z]?\b',
          caseSensitive: false,
        ).hasMatch(loc)) {
          return false;
        }

        return true;
      }, orElse: () => null);
      return result;
    } catch (e) {
      return null;
    }
  }

  void download() async {
    if (downloaded) return;

    setState(() {
      downloaded = true;
    });

    File basicFile = File(file.path); // cant give saveFile XFile :p

    await FlutterImageGallerySaver.saveFile(basicFile.path);
  }

  void toggleAll() {
    setState(() {
      if (!all || uids.isEmpty) {
        for (dynamic u in users) {
          uids.add(u['uid']);
          all = true;
        }
      } else {
        uids.clear();
        all = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;
    users = user['friends'];
    dynamic screenWidth = MediaQuery.of(context).size.width;
    dynamic bigWidth = (screenWidth * 0.8) - 5;
    dynamic smallWidth = (screenWidth * 0.2) - 5;

    List<Widget> widgets = [];

    for (dynamic friend in users) {
      widgets.add(
        ElevatedButton(
          onPressed: () {
            if (sending) return;

            setState(() {
              if (uids.contains(friend['uid'])) {
                uids.removeWhere((uid) => uid == friend['uid']);
              } else {
                uids.add(friend['uid']);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: ExtendedImage.network(
                      imgUrl(friend['uid']),
                      height: 72,
                      width: 72,
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
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend['nick'],
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
              uids.contains(friend['uid']) && allowSave
                  ? Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff7ceece),
                    ),
                  )
                  : uids.contains(friend['uid']) && !allowSave
                  ? Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xfffd95fd),
                    ),
                  )
                  : Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                  ),
            ],
          ),
        ),
      );
      if (user['friends'][user['friends'].length - 1]['uid'] == friend['uid']) {
        continue;
      }
      widgets.add(SizedBox(height: 25));
    }

    void pokeNow() async {
      if (uids.isEmpty || sending) return;
      setState(() {
        sending = true;
      });

      dynamic geo = await gimmeLocation(usr);

      dynamic re = await pMultipart(
        p: '/poke',
        data: {
          'is': whatis,
          'uids': jsonEncode(uids.toList()),
          'allowSave': allowSave,
          'geo': geo,
        },
        file: file,
        mime: whatis == 'img' ? 'image/jpeg' : 'video/mp4',
        token: usr.token,
      );

      if (re['statusCode'] != 200) {
        setState(() {
          sending = false;
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Chat()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              controller: ani,
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 120,
                          width: double.infinity,
                          child:
                              whatis == 'img'
                                  ? Image.file(
                                    File(file.path),
                                    fit: BoxFit.cover,
                                  )
                                  : PokeVideo(url: file.path, file: true),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: MediaQuery.of(context).padding.top + 50,
                          decoration: BoxDecoration(color: Colors.transparent),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Poking~',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(width: 50),
                                ],
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => download(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF80FFCC),
                                      Color(0xFFAAFEEA),
                                      Colors.tealAccent,
                                    ],
                                    begin: Alignment.bottomRight,
                                    end: Alignment.topLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      downloaded
                                          ? 'images/download-complete.svg'
                                          : 'images/download.svg',
                                      height: 40,
                                      width: 40,
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
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => toggleAll(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'eve',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 20),
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      !allowSave
                                          ? Color(0xfffd95fd)
                                          : Color(0xff7ceece),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 60 + 25,
                      left: 16,
                      right: 16,
                    ),
                    child:
                        loading
                            ? Center(
                              child: LoadingAnimationWidget.waveDots(
                                color: Colors.white,
                                size: 35,
                              ),
                            )
                            : widgets.isEmpty
                            ? Column(
                              children: [
                                Center(
                                  child: SvgPicture.asset(
                                    'images/clown-face.svg',
                                    height: 55,
                                    width: 55,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    'No friends to poke-',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Column(children: widgets),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child:
                  uids.isNotEmpty
                      ? Row(
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            width: allowSave ? bigWidth : smallWidth,
                            height: 60,
                            curve: Curves.easeInOut,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (sending) return;
                                if (allowSave) {
                                  pokeNow();
                                  return;
                                }
                                setState(() {
                                  allowSave = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF80FFCC),
                                      Color(0xFFAAFEEA),
                                      Colors.tealAccent,
                                    ],
                                    begin: Alignment.bottomRight,
                                    end: Alignment.topLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Center(
                                  child:
                                      sending && allowSave
                                          ? LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 35,
                                          )
                                          : allowSave
                                          ? Text(
                                            'poke~',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            width: !allowSave ? bigWidth : smallWidth,
                            height: 60,
                            curve: Curves.easeInOut,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (sending) return;
                                if (!allowSave) {
                                  pokeNow();
                                  return;
                                }
                                setState(() {
                                  allowSave = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF7CE1),
                                      Color(0xFFFFAEFF),
                                      Color(0xFFFF77FF),
                                    ],
                                    begin: Alignment.bottomRight,
                                    end: Alignment.topLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Center(
                                  child:
                                      sending && !allowSave
                                          ? LoadingAnimationWidget.waveDots(
                                            color: Colors.white,
                                            size: 35,
                                          )
                                          : !allowSave
                                          ? Text(
                                            'ghost~',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Icon(
                                            Icons.near_me_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
