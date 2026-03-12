import 'package:flutter/material.dart';
import 'package:poke/components/chat_bubble.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:extended_image/extended_image.dart';
import '../components/safe_bar.dart';
import '../components/nav_bar.dart';
import '../components/gallery.dart';
import '../components/call_api.dart';
import '../components/functions.dart';
import './edit.dart';

class Me extends StatefulWidget {
  const Me({super.key});

  @override
  State<Me> createState() => _Me();
}

class _Me extends State<Me> {
  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic user = usr.user;

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
                  top: MediaQuery.of(context).padding.top + 80,
                  bottom: 56 + 20,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipOval(
                                    child: ExtendedImage.network(
                                      imgUrl(user['uid']),
                                      height: 100,
                                      width: 100,
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
                                  SizedBox(height: 15),
                                  Text(
                                    'You\'ve poked ${comify(user['p'])} times!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Edit(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                    ),
                                    child: Text(
                                      'edit',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ChatBubble(
                                  child: Text(
                                    '/ᐠ - ˕ -マ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 120), // 1x user image + 25
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 40,
                                    ), // 2nd bubble a bit down
                                    ChatBubble(
                                      left: true,
                                      child: Text(
                                        ' ᶻ 𝘇 𐰁 ',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20), // too keep things ✨
                              ],
                            ),
                          ],
                        ),
                        Gallery(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeBar(title: user['nick']),
            NavBar(dontOpen: 'me'),
          ],
        ),
      ),
    );
  }
}
