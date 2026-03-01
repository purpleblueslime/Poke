import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:poke/components/safe_bar.dart';
import 'package:poke/pages/login_new.dart';
import 'dart:convert';
import '../components/call_api.dart';
import 'login_with_code.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogIn();
}

class _LogIn extends State<LogIn> {
  dynamic email = TextEditingController();
  dynamic allow = false;
  dynamic loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    'By giving us your email, you agree to our tos.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
                            'What\'s your email',
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
                                  controller: email,
                                  onChanged: (text) {
                                    dynamic emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );

                                    setState(() {
                                      allow = emailRegex.hasMatch(text.trim());
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
                                    hintText: 'email',
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
                                email.text.isEmpty || !allow
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
                                if (email.text.isEmpty || !allow) {
                                  return;
                                }

                                setState(() {
                                  loading = true;
                                });

                                dynamic re = await p('/login', {
                                  'email': email.text.trim(),
                                });

                                if (re.statusCode != 200) {
                                  setState(() {
                                    loading = false;
                                  });
                                  return;
                                }

                                dynamic data = json.decode(re.body);

                                if (data['uid'] == null) {
                                  setState(() {
                                    loading = false;
                                  });

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LoginNew(
                                            email: email.text.trim(),
                                          ),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  loading = false;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => LoginWithCode(
                                          email: email.text.trim(),
                                        ),
                                  ),
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
                                        'next',
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
            SafeBar(title: 'Poke'),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    email.dispose();
    super.dispose();
  }
}
