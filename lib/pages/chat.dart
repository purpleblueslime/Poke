import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import '../components/call_api.dart';
import '../components/safe_bar.dart';
import '../components/nav_bar.dart';
import '../components/functions.dart';
import './open_poke.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _Chat();
}

class _Chat extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;

    List<Widget> widgets = [];

    for (dynamic poke in user['pokes']) {
      if (poke['opened'] && !poke['allowSave']) continue;

      widgets.add(
        ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OpenPoke(poke: poke)),
            );

            if (!poke['opened']) {
              poke['opened'] = true;
              usr.setUser(user);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          child: SizedBox(
            height: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    RepaintBoundary(
                      child: Stack(
                        children: [
                          ClipOval(
                            child: ExtendedImage.network(
                              imgUrl(poke['by']['uid']),
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
                          poke['by']['streaks'] <= 0
                              ? SizedBox.shrink()
                              : Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
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
                                      Text(
                                        '${poke['by']['streaks']}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          poke['by']['nick'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            !poke['opened']
                                ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        !poke['allowSave']
                                            ? Color(0xfffd95fd)
                                            : Color(0xff7ceece),
                                  ),
                                )
                                : SizedBox.shrink(),
                            SizedBox(width: !poke['opened'] ? 5 : 0),
                            Text(
                              !poke['allowSave']
                                  ? 'Ghosted you!'
                                  : !poke['opened']
                                  ? 'New poke!'
                                  : 'Poked you!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              timeify(DateTime.parse(poke['createdAt'])),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    poke['geo'] == null
                        ? SizedBox.shrink()
                        : SizedBox(
                          width: MediaQuery.of(context).size.width - 300,
                          child: Text(
                            textAlign: TextAlign.right,
                            poke['geo'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff80ffcc),
                            ),
                            softWrap: true,
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
                        poke['geo'] == null ? Colors.white : Color(0xff80ffcc),
                        BlendMode.srcIn,
                      ),
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      widgets.add(SizedBox(height: 15));
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
                  Padding(
                    padding: EdgeInsets.only(
                      top:
                          MediaQuery.of(context).padding.top +
                          76, // safeBar + 16
                      bottom: 66 + 16, // navBar + 16
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              usr.setOptions({'isGeo': !usr.options['isGeo']});
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: SizedBox(
                              child: Ink(
                                decoration:
                                    usr.options['isGeo']
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
                                            20,
                                          ),
                                        )
                                        : BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Location is ${usr.options['isGeo'] ? 'on' : 'off'}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Want to share your location with pokes?',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SvgPicture.asset(
                                        'images/navigation.svg',
                                        height: 35,
                                        width: 35,
                                        colorFilter: ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        alignment: Alignment.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          widgets.isNotEmpty
                              ? Column(children: widgets)
                              : Column(
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
                                      'No pokes right now!',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeBar(title: 'Chat'),
            NavBar(dontOpen: 'chat'),
          ],
        ),
      ),
    );
  }
}
