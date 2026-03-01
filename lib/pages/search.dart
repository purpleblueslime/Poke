import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import '../components/call_api.dart';
import '../components/popup.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _Search();
}

class _Search extends State<Search> {
  dynamic users = [];
  dynamic loading = false;
  dynamic bounce;
  dynamic confirmSpin = [];
  dynamic deleteSpin = [];
  dynamic searchThis;

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;

    searchNow(text) async {
      if (text.isEmpty) {
        setState(() {
          users = [];
          loading = false;
        });
        return;
      }

      dynamic re = await g('/search?q=$text', usr.token);

      if (re.statusCode != 200) {
        setState(() {
          users = [];
          loading = false;
        });
        return;
      }

      dynamic data = json.decode(re.body);
      setState(() {
        users = data['users'];
        loading = false;
      });
      return;
    }

    okConfirm(context, u) {
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
            ),
          ),
          content: popUp(context, [
            ClipOval(
              child: ExtendedImage.network(
                imgUrl(u['uid']),
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
                fontSize: 19,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(
                  context,
                ).removeCurrentSnackBar(reason: SnackBarClosedReason.remove);

                if (deleteSpin.contains(u['uid'])) return;
                setState(() {
                  deleteSpin.add(u['uid']);
                });

                dynamic re = await g(
                  '/friends/unfriend?uid=${u['uid']}',
                  usr.token,
                );

                if (re.statusCode != 200) {
                  setState(() {
                    deleteSpin.removeWhere((uid) => uid == u['uid']);
                  });
                  return;
                }

                await usr.refresh();
                await searchNow(searchThis);
                setState(() {
                  deleteSpin.removeWhere((uid) => uid == u['uid']);
                });
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

    List<Widget> widgets = [];

    for (dynamic u in users) {
      widgets.add(
        GestureDetector(
          child: Row(
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
              u['as'] == 'request'
                  ? Row(
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
                          await searchNow(searchThis);
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
                                  'confirm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
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
                          await searchNow(searchThis);
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
                                  'delete',
                                  style: TextStyle(fontSize: 14),
                                ),
                      ),
                    ],
                  )
                  : u['as'] == 'requested'
                  ? ElevatedButton(
                    onPressed: () async {
                      if (deleteSpin.contains(u['uid'])) return;
                      setState(() {
                        deleteSpin.add(u['uid']);
                      });

                      dynamic re = await g(
                        '/friends/unsend?uid=${u['uid']}',
                        usr.token,
                      );

                      if (re.statusCode != 200) {
                        setState(() {
                          deleteSpin.removeWhere((uid) => uid == u['uid']);
                        });
                        return;
                      }

                      dynamic i = users.indexWhere(
                        (usr) => usr['uid'] == u['uid'],
                      );
                      users[i]['as'] = 'ghost';
                      usr.setUser(user);

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
                            : Text('unsend', style: TextStyle(fontSize: 15)),
                  )
                  : u['as'] == 'friend'
                  ? ElevatedButton(
                    onPressed: () async {
                      if (deleteSpin.contains(u['uid'])) return;
                      okConfirm(context, u);
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
                            : Text('unfriend', style: TextStyle(fontSize: 15)),
                  )
                  : ElevatedButton(
                    onPressed: () async {
                      if (confirmSpin.contains(u['uid'])) return;
                      setState(() {
                        confirmSpin.add(u['uid']);
                      });

                      dynamic re = await g(
                        '/friends/send?uid=${u['uid']}',
                        usr.token,
                      );

                      if (re.statusCode != 200) {
                        setState(() {
                          confirmSpin.removeWhere((uid) => uid == u['uid']);
                        });
                        return;
                      }

                      dynamic i = users.indexWhere(
                        (usr) => usr['uid'] == u['uid'],
                      );
                      users[i]['as'] = 'requested';
                      usr.setUser(user);

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
                              'add',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                  ),
            ],
          ),
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
                    loading
                        ? Center(
                          child: LoadingAnimationWidget.waveDots(
                            color: Colors.white,
                            size: 35,
                          ),
                        )
                        : users.length == 0
                        ? Column(
                          children: [
                            Center(
                              child: SvgPicture.asset(
                                'images/loudly-crying-face.svg',
                                height: 55,
                                width: 55,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: Text(
                                'No one with that nick-',
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
                height: MediaQuery.of(context).padding.top + 120,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 6,
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 15),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, user);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.all(8),
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
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: TextField(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    onChanged: (text) async {
                                      setState(() {
                                        searchThis = text;
                                        loading = true;
                                      });

                                      if (bounce?.isActive == true) {
                                        bounce.cancel();
                                      }

                                      bounce = Timer(
                                        Duration(seconds: 1),
                                        () async {
                                          await searchNow(text);
                                        },
                                      );
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
