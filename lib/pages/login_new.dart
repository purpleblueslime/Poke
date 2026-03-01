import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:io';
import '../components/call_api.dart';
import './cam.dart';

class LoginNew extends StatefulWidget {
  final dynamic email;

  const LoginNew({super.key, this.email});

  @override
  State<LoginNew> createState() => _LoginNew();
}

class _LoginNew extends State<LoginNew> {
  late dynamic email;
  dynamic userImage;
  dynamic code = TextEditingController();
  dynamic nick = TextEditingController();
  late dynamic nickLen = nick.text.length;
  dynamic loading = false;
  dynamic allow = false;
  dynamic error = false;

  @override
  initState() {
    super.initState();
    email = widget.email;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.transparent,
              height: double.infinity,
              width: double.infinity,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                        left: 25,
                        right: 25,
                      ),
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
                                children: [
                                  userImage == null
                                      ? SizedBox.shrink()
                                      : ClipOval(
                                        child: Image.file(
                                          userImage as File,
                                          height: 120,
                                          width: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  Center(
                                    child: SizedBox.expand(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 25),
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
                              nickLen > 10
                                  ? Row(
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
                                  )
                                  : SizedBox.shrink(),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text(
                            'We\'ve send you OTP',
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
                                  controller: code,
                                  onChanged: (text) {
                                    dynamic rx = RegExp(r'^\d+$');
                                    setState(() {
                                      if (text.length == 6 &&
                                          rx.hasMatch(text)) {
                                        allow = true;
                                      } else {
                                        allow = false;
                                      }
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
                                    hintText: 'OTP',
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
                            ],
                          ),
                          SizedBox(height: 15),
                          Container(
                            decoration:
                                code.text.isEmpty ||
                                        nick.text.trim().isEmpty ||
                                        nick.text.trim().length > 10 ||
                                        userImage == null ||
                                        !allow
                                    ? BoxDecoration()
                                    : BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xff80ffcc),
                                          Color(0xffaafeea),
                                          Colors.tealAccent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (code.text.isEmpty ||
                                    nick.text.trim().isEmpty ||
                                    nick.text.trim().length > 10 ||
                                    userImage == null ||
                                    !allow) {
                                  return;
                                }

                                setState(() {
                                  error = false;
                                  loading = true;
                                });

                                dynamic re = await pMultipart(
                                  p: '/login/new',
                                  data: {
                                    'email': email,
                                    'code': code.text,
                                    'nick': nick.text.trim(),
                                  },
                                  file: XFile(userImage.path),
                                  mime: 'image/gif',
                                  name: 'image',
                                  token: 'Ehe gimme token',
                                );

                                if (re['statusCode'] != 200) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return;
                                }

                                dynamic data = re['data'];
                                if (data == null || data['token'] == null) {
                                  setState(() {
                                    error = true;
                                    loading = false;
                                  });
                                  return;
                                }

                                dynamic u = Provider.of<UserPro>(
                                  context,
                                  listen: false,
                                );
                                await u.setToken(data['token']);
                                await u.refresh();
                                await u.setFcmToken();

                                setState(() {
                                  loading = false;
                                });

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Cam(),
                                  ),
                                  (Route<dynamic> route) =>
                                      false, // override all pages
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child:
                                  loading
                                      ? LoadingAnimationWidget.waveDots(
                                        color: Colors.white,
                                        size: 35,
                                      )
                                      : Text(
                                        'login',
                                        style: TextStyle(
                                          fontSize: 19,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            error
                ? Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 8,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'OTP is not correct ;-;',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                : SizedBox.shrink(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).padding.top + 60, // safeBar height
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
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
                            Text(
                              'New to Poke',
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
    code.dispose();
    super.dispose();
  }
}
