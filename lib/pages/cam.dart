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
  late MethodChannel channel;
  dynamic id;

  late DateTime touch;
  Timer? touchBounce;
  dynamic cameraReady = false;

  dynamic poking = false;

  late AnimationController ani;
  late Animation<Color?> blinkingColor;
  dynamic _radius = 55.0;

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

  initOptions(channel) {
    Future.microtask(() async {
      dynamic usr = Provider.of<UserPro>(context, listen: false);
      dynamic options = usr.options;

      if (options['isFlash']) {
        await channel.invokeMethod('toggleFlash');
      }
      if (!options['isNoise']) {
        await channel.invokeMethod('toggleNoise');
      }
    });
  }

  @override
  initState() {
    super.initState();

    channel = MethodChannel('poke_camera');

    initOptions(channel);
    initCamera();

    ani = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);

    blinkingColor = ColorTween(
      begin: Color(0xff7ceece).withOpacity(0),
      end: Color(0xff7ceece).withOpacity(1),
    ).animate(ani);
  }

  late XFile videoFile;
  dynamic isRecording = false;
  dynamic max = 30;
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

      await channel.invokeMethod('startRecording');

      setState(() {
        _radius = 20.0;
        isRecording = true;
        timeRn = 0;
      });
      updateprogress();
    }

    toggleFlash() async {
      if (isRecording || !cameraReady) return; // uh otherwise breaks ;-;
      await channel.invokeMethod('toggleFlash');
      await setOptions({'isFlash': !options['isFlash']});
    }

    toggleNoise() async {
      if (isRecording || !cameraReady) return; // same ;-;
      await channel.invokeMethod('toggleNoise');
      await setOptions({'isNoise': !options['isNoise']});
    }

    toggleCamera() async {
      if (isRecording || !cameraReady) return; // sme
      await channel.invokeMethod('toggleCamera');
      await channel.invokeMethod('stopCamera'); // kill cam
      await initCamera(); // reinit
    }

    takePhoto() async {
      if (!cameraReady) return;
      if (isRecording) return; // otherwise brokey
      if (poking) return;
      setState(() {
        poking = true;
      });

      dynamic path = await channel.invokeMethod('takePhoto');
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
                          color: Color(0xff7ceece),
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
                                        : Color(0xff7ceece),
                                borderRadius: BorderRadius.circular(_radius),
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 90, // safeBar + 30
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
            SafeBar(title: 'Poke~'),
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
