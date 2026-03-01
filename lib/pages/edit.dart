import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:io';
import '../components/call_api.dart';

class Edit extends StatefulWidget {
  const Edit({super.key});

  @override
  State<Edit> createState() => _Edit();
}

class _Edit extends State<Edit> {
  dynamic pickImage() async {
    dynamic pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        userImage = File(pickedFile.path);
      });
    }
  }

  dynamic user;
  File? userImage;
  dynamic uploading = false;

  late dynamic nick = TextEditingController(text: user['nick']);
  late dynamic nickLen = nick.text.length;

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);

    setState(() {
      user = usr.user;
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 16),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  pickImage();
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                              ),
                              child: Container(
                                width: 120,
                                height: 120,
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 5,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipOval(
                                      child:
                                          userImage == null
                                              ? ExtendedImage.network(
                                                imgUrl(user['uid']),
                                                height: 120,
                                                width: 120,
                                                fit: BoxFit.cover,
                                                cache: true,
                                                cacheMaxAge: Duration(days: 1),
                                                loadStateChanged: (state) {
                                                  if (state
                                                          .extendedImageLoadState ==
                                                      LoadState.completed) {
                                                    return null;
                                                  } else {
                                                    return SizedBox.shrink();
                                                  }
                                                },
                                              )
                                              : Image.file(
                                                userImage as File,
                                                height: 120,
                                                width: 120,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    SvgPicture.asset(
                                      'images/add.svg',
                                      height: 40,
                                      width: 40,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'What your friends know you as',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nick,
                                    onChanged: (text) {
                                      setState(() {
                                        nickLen = text.length;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'nick',
                                      hintStyle: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                nickLen <= 10
                                    ? SizedBox.shrink()
                                    : Row(
                                      children: [
                                        Text(
                                          'too big',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 7),
                                        SvgPicture.asset(
                                          'images/clown-face.svg',
                                          height: 20,
                                          width: 20,
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () async {
                                if (uploading ||
                                    nickLen < 0 ||
                                    nick.text.trim().isEmpty) {
                                  return;
                                }

                                setState(() {
                                  uploading = true;
                                });

                                if (nick.text == user['nick'] &&
                                    userImage == null) {
                                  Navigator.pop(context, user);
                                }

                                dynamic re = await pMultipart(
                                  p: '/me/update',
                                  data: {'nick': nick.text.trim()},
                                  file:
                                      userImage == null
                                          ? null
                                          : XFile(userImage!.path),
                                  name: 'image',
                                  mime: 'image/gif',
                                  token: usr.token,
                                );

                                if (re['statusCode'] != 200) {
                                  setState(() {
                                    uploading = false;
                                  });
                                  return;
                                }

                                if (userImage != null) {
                                  // idk smtimes without these it dont work
                                  clearMemoryImageCache(imgUrl(user['uid']));

                                  // actual cache clear
                                  await ExtendedNetworkImageProvider(
                                    imgUrl(user['uid']),
                                  ).evict(includeLive: true);
                                }
                                usr.refresh();

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    nickLen > 10 || nick.text.isEmpty
                                        ? Colors.black
                                        : Color(0xff7ceece),
                              ),
                              child:
                                  uploading
                                      ? LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 25,
                                      )
                                      : Text(
                                        'save',
                                        style: TextStyle(
                                          fontSize: 19,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
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
                              'Edit',
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

  @override
  dispose() {
    nick.dispose();
    super.dispose();
  }
}
