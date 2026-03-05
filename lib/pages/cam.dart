import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart'; // for XFile uwu
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'dart:async';
import '../components/safe_bar.dart';
import '../components/nav_bar.dart';
import './send_poke.dart';

class Cam extends StatefulWidget {
  const Cam({super.key});

  @override
  State<Cam> createState() => _Cam();
}

class _Cam extends State<Cam> with TickerProviderStateMixin {
  dynamic filters = [
    {'nick': 'Swipe to apply filters'}, // no filter
    {'nick': 'Interstellar', 'img': 'interstellar.jpg'},
    {'nick': 'Batman', 'img': 'batman.jpg'},
    {'nick': 'Breaking Bad', 'img': 'breaking_bad.jpg'},
  ];

  late MethodChannel channel;
  dynamic id;

  late DateTime touch;
  Timer? touchBounce;
  dynamic cameraReady = false;

  dynamic poking = false;

  late AnimationController ani;
  late Animation<Color?> blinkingColor;
  dynamic _radius = 55.0;

  dynamic filter = 0; // uh need for toggleCam

  dynamic initCamera() async {
    try {
      id = await channel.invokeMethod('startCamera');

      setState(() {
        cameraReady = true;
      });
    } catch (_) {
      setState(() {
        cameraReady = false; // user didnt give permission to cam ;-;
      });
    }
  }

  @override
  initState() {
    super.initState();

    channel = MethodChannel('poke_camera');

    initCamera();

    ani = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);

    blinkingColor = ColorTween(
      begin: Color(0xff00c8ff).withOpacity(0),
      end: Color(0xff00c8ff).withOpacity(1),
    ).animate(ani);
  }

  late XFile videoFile;
  dynamic isRecording = false;
  dynamic max = 5; // only allow 3secs snaps (vercel back limit) ;-; (fix maybe)
  dynamic timeRn = 0;

  poke(file, whatIs) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendPoke(file: file, whatis: whatIs),
      ),
    );

    setState(() {
      poking = false;
      _radius = 55.0;
      if (whatIs != 'img') {
        timeRn = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    dynamic usr = Provider.of<UserPro>(context);
    dynamic setOptions = usr.setOptions;
    dynamic options = usr.options;

    stopRecording() async {
      if (poking) return;
      if (!isRecording) return;
      setState(() {
        poking = true;
        isRecording = false;
      });

      dynamic path = await channel.invokeMethod('stopRecording');
      XFile file = XFile(path);
      poke(file, 'mp4');
    }

    updateprogress() {
      if (!isRecording) return;
      if (poking) return;

      if (timeRn > max) {
        stopRecording();
        return;
      }

      Future.delayed(Duration(seconds: 1), () {
        if (!isRecording) return;
        setState(() {
          timeRn++;
        });
        updateprogress();
      });
    }

    startRecording() async {
      if (!cameraReady) return;

      if (poking) return;

      if (isRecording) return;

      await channel.invokeMethod('startRecording', {
        'flash': options['isFlash'],
        'noise': options['isNoise'],
      });

      setState(() {
        _radius = 20.0;
        isRecording = true;
        timeRn = 0;
      });
      updateprogress();
    }

    toggleFlash() async {
      if (isRecording || !cameraReady || poking) return; // otherwise breaks ;-;
      await setOptions({'isFlash': !options['isFlash']});
    }

    toggleNoise() async {
      if (isRecording || !cameraReady || poking) return; // same ;-;
      await setOptions({'isNoise': !options['isNoise']});
    }

    toggleCamera() async {
      if (isRecording || !cameraReady || poking) return; // sme
      await channel.invokeMethod('toggleCamera');
      await initCamera(); // reinit
      await channel.invokeMethod('changeFilter', {'id': filter});
    }

    takePhoto() async {
      if (!cameraReady) return;
      if (isRecording) return; // otherwise brokey
      if (poking) return;
      setState(() {
        poking = true;
      });

      dynamic path = await channel.invokeMethod('takePhoto', {
        'flash': options['isFlash'],
      });
      XFile file = XFile(path);
      poke(file, 'img');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cameraReady
                ? GestureDetector(
                  onDoubleTap: toggleCamera,
                  child: Center(child: Texture(textureId: id)),
                )
                : SizedBox.shrink(),
            Positioned(
              bottom: 96, // navBar + 30
              left: 0,
              right: 0,
              child: Center(
                child:
                    poking
                        ? LoadingAnimationWidget.beat(
                          color: Color(0xff00c8ff),
                          size: 100,
                        )
                        : GestureDetector(
                          behavior: HitTestBehavior.opaque, // needed to hit
                          child: Listener(
                            // gesture in gesture won't work
                            onPointerDown: (_) {
                              touch = DateTime.now();
                              touchBounce = Timer(
                                Duration(milliseconds: 500),
                                () {
                                  startRecording(); // record if 500ms <
                                },
                              );
                            },
                            onPointerUp: (_) {
                              touchBounce?.cancel();

                              dynamic duration = DateTime.now().difference(
                                touch,
                              );

                              if (duration < Duration(milliseconds: 500)) {
                                takePhoto(); // touch
                              } else {
                                // long touch
                                stopRecording();
                              }
                            },
                            child: AnimatedContainer(
                              curve: Curves.easeInOut,
                              duration: Duration(seconds: 1),
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                color:
                                    _radius == 55.0
                                        ? Colors.white
                                        : Color(0xff00c8ff),
                                borderRadius: BorderRadius.circular(_radius),
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 90, // safeBar + 30
              right: 0,
              left: 0,
              child: SizedBox(
                height: 90,
                child: PageView.builder(
                  controller: PageController(
                    initialPage: filters.length * 1000,
                  ), // to get them back swipes ;)
                  onPageChanged: (item) async {
                    dynamic id = item % filters.length;
                    await channel.invokeMethod('changeFilter', {'id': id});
                    setState(() {
                      filter = id; // inf swipes
                    });
                  },
                  itemCount: filters.length * 2000, // not really inf but works
                  itemBuilder: (context, itm) {
                    dynamic item = itm % filters.length; // inf swipes also
                    return Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          isRecording || poking
                              ? SizedBox.shrink()
                              : Text(
                                filters[item]['nick'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                height: 65,
                                width: 65,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 5,
                                  ),
                                ),
                                child:
                                    item == 0
                                        ? Center(
                                          child: SvgPicture.asset(
                                            'images/gesture.svg',
                                            height: 30,
                                            width: 30,
                                            colorFilter: ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.srcIn,
                                            ),
                                            alignment: Alignment.center,
                                          ),
                                        )
                                        : ClipOval(
                                          child: Image.asset(
                                            'images/${filters[item]['img']}',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 180, // safeBar + 120
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: toggleFlash,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.all(5),
                        ),
                        child: SvgPicture.asset(
                          options['isFlash']
                              ? 'images/flash-on.svg'
                              : 'images/flash-off.svg',
                          height: 30,
                          width: 30,
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          alignment: Alignment.center,
                        ),
                      ),
                      SizedBox(height: 2),
                      ElevatedButton(
                        onPressed: toggleNoise,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.all(5),
                        ),
                        child: SvgPicture.asset(
                          options['isNoise']
                              ? 'images/blur-on.svg'
                              : 'images/blur-off.svg',
                          height: 30,
                          width: 30,
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          alignment: Alignment.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 90, // safeBar + 30
              left: 0,
              right: 0,
              child:
                  timeRn != 0
                      ? Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: blinkingColor,
                              builder: (context, child) {
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: blinkingColor.value,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 10),
                            Text(
                              '00:${timeRn > 9 ? timeRn : '0$timeRn'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : SizedBox.shrink(),
            ),
            SafeBar(title: 'Poke'),
            NavBar(dontOpen: 'cam'),
          ],
        ),
      ),
    );
  }

  @override
  dispose() {
    channel.invokeMethod('stopCamera');
    ani.dispose();
    super.dispose();
  }
}
