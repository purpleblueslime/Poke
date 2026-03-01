import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'dart:convert';
import '../components/call_api.dart';
import 'cam.dart';

class LoginWithCode extends StatefulWidget {
  final dynamic email;

  const LoginWithCode({super.key, this.email});

  @override
  State<LoginWithCode> createState() => _LoginWithCode();
}

class _LoginWithCode extends State<LoginWithCode> {
  late dynamic email;
  dynamic code = TextEditingController();
  dynamic loading = false;
  dynamic allow = false;
  dynamic error = false;

  @override
  initState() {
    super.initState();
    email = widget.email;
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
                          Text(
                            'We\'ve send you OTP',
                            style: TextStyle(
                              fontSize: 40,
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
                                code.text.isEmpty || !allow
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
                                if (code.text.isEmpty || !allow) {
                                  return;
                                }

                                setState(() {
                                  error = false;
                                  loading = true;
                                });

                                dynamic re = await p('/login/withCode', {
                                  'email': email,
                                  'code': code.text,
                                });

                                if (re.statusCode != 200) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return;
                                }

                                dynamic data = json.decode(re.body);
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
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
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
                              'Login to Poke',
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
    code.dispose();
    super.dispose();
  }
}
