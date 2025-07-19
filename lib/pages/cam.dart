import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../user_provider.dart';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  late CameraController camera;
  late List<dynamic> cameras;
  late DateTime touch;
  Timer? touchBounce;
  bool cameraReady = false;
  dynamic camerai = 0;
  bool poking = false;

  late AnimationController ani;
  late Animation<Color?> blinkingColor;
  dynamic _radius = 55.0;

  bool showBloom = false;
  bool showFlash = false;
  bool showNoise = false;
  dynamic bloomBounce;
  dynamic flashBounce;
  dynamic noiseBounce;

  dynamic zoom = 1;
  dynamic maxZoom = 8;
  dynamic minZoom = 1;

  Future<void> initCamera([int cami = 0]) async {
    if (cameraReady) return; // dont reinit
    cameras = await availableCameras();
    camerai = cami;
    camera = CameraController(cameras[camerai], ResolutionPreset.veryHigh);
    await camera.initialize();
    await camera.setFlashMode(FlashMode.off); // flash makes slow
    setState(() {
      cameraReady = true;
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to init
    if (!cameraReady) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void initState() {
    super.initState();

    initCamera();

    ani = AnimationController(duration: Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);

    blinkingColor = ColorTween(
      begin: Color(0xff7ceece).withOpacity(0),
      end: Color(0xff7ceece).withOpacity(1),
    ).animate(ani);
  }

  void toggleCamera() async {
    if (isRecording) return;
    if (poking) return;

    int newi = camerai == 0 ? 1 : 0;
    setState(() {
      cameraReady = false;
    });
    await camera.dispose();
    await initCamera(newi);
  }

  late XFile videoFile;
  bool isRecording = false;
  int max = 30;
  int timeRn = 0;

  void poke(file, whatIs, noise, bloom) async {
    dynamic isFront =
        cameras[camerai].lensDirection == CameraLensDirection.front
            ? bloom
                ? 'hflip,'
                : '-vf hflip'
            : '';

    dynamic filterComplex =
        bloom
            ? '-filter_complex '
                '"'
                'split=4[in1][in2][in3][in4];'
                '[in2]gblur=sigma=6,eq=brightness=0.04:saturation=1.08[bloom];'
                '[in1][bloom]overlay=format=auto:shortest=1:alpha=0.32[bloomed];'
                '[in3]gblur=sigma=8,eq=brightness=0.035:saturation=1.0,colorchannelmixer=aa=0.28[hal];'
                '[bloomed][hal]overlay=format=auto:shortest=1:alpha=0.28[hal_bloomed];'
                '[hal_bloomed]chromashift=cbh=4:crh=-4:cbv=-2:crv=2[prism];'
                '[in4]gblur=sigma=8,eq=brightness=0.03:saturation=0.95,'
                'colorchannelmixer=aa=0.10[reflection];'
                '[prism][reflection]overlay=format=auto:shortest=1:alpha=0.10[reflected];'
                '[reflected]gblur=sigma=1.0,eq=contrast=1.02:saturation=1.06:brightness=0.015[diffused];'
                '[diffused]noise=alls=3:allf=t[filmgrain];'
                '[filmgrain]eq=contrast=1.03:saturation=1.07:brightness=0.02,'
                '$isFront'
                'colorlevels='
                'rimin=0.10:gimin=0.10:bimin=0.10:'
                'rimax=0.99:gimax=0.99:bimax=0.99[out]'
                '" '
                '-map "[out]" -map 0:a?'
            : isFront;

    dynamic ops =
        whatIs == 'img'
            ? ''
            : !noise
            ? '-an'
            : '-c:a copy';

    dynamic fmt = whatIs == 'img' ? 'jpg' : 'mp4';
    dynamic o = '${file.path}poke.$fmt';
    dynamic isImg =
        whatIs == 'img'
            ? ''
            : '-c:v libx264 -pix_fmt yuv420p -crf 23 -preset veryfast';

    dynamic cmd = '-y -i "${file.path}" $filterComplex $ops $isImg "$o"';

    await FFmpegKit.execute(cmd);

    file = XFile(o);

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

    void stopRecording() async {
      if (poking) return;
      if (!isRecording) return;
      setState(() {
        poking = true;
        isRecording = false;
      });

      XFile file = await camera.stopVideoRecording();
      if (options['isFlash']) await camera.setFlashMode(FlashMode.off);
      poke(file, 'mp4', options['isNoise'], options['isBloom']);
    }

    void updateprogress() {
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

    void startRecording() async {
      if (!cameraReady) return;

      if (poking) return;

      if (isRecording) return;

      if (options['isFlash']) await camera.setFlashMode(FlashMode.torch);
      await camera.startVideoRecording();

      setState(() {
        _radius = 20.0;
        isRecording = true;
        timeRn = 0;
      });
      updateprogress();
    }

    void toggleBloom() async {
      if (poking) return;
      if (bloomBounce != null) {
        bloomBounce.cancel();
      }

      await setOptions({'isBloom': !options['isBloom']});

      setState(() {
        showBloom = true;
      });

      bloomBounce = Timer(Duration(seconds: 2), () {
        setState(() {
          showBloom = false;
          bloomBounce = null;
        });
      });
    }

    void toggleFlash() async {
      if (poking) return;
      if (flashBounce != null) {
        flashBounce.cancel();
      }

      await setOptions({'isFlash': !options['isFlash']});

      setState(() {
        showFlash = true;
      });

      flashBounce = Timer(Duration(seconds: 2), () {
        setState(() {
          showFlash = false;
          flashBounce = null;
        });
      });
    }

    void toggleNoise() async {
      if (poking) return;
      if (noiseBounce != null) {
        noiseBounce.cancel();
      }

      await setOptions({'isNoise': !options['isNoise']});

      setState(() {
        showNoise = true;
      });

      noiseBounce = Timer(Duration(seconds: 2), () {
        setState(() {
          showNoise = false;
          noiseBounce = null;
        });
      });
    }

    void takePhoto() async {
      if (!cameraReady) return;
      if (isRecording) return; // otherwise brokey
      if (poking) return;
      if (options['isFlash']) await camera.setFlashMode(FlashMode.torch);
      setState(() {
        poking = true;
      });

      XFile file = await camera.takePicture();
      if (options['isFlash']) await camera.setFlashMode(FlashMode.off);
      poke(file, 'img', options['isNoise'], options['isBloom']);
    }

    void updateZoom(DragUpdateDetails details) async {
      dynamic sensy = 0.04; // play around with this to find that sweet spot
      dynamic delta = -details.delta.dy * sensy;
      dynamic newZoom = (zoom + delta).clamp(minZoom, maxZoom);

      if ((newZoom - zoom).abs() < 0.01) return;

      await camera.setZoomLevel(newZoom);
      setState(() {
        zoom = newZoom;
      });
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
                  onVerticalDragUpdate: updateZoom,
                  onDoubleTap: () => toggleCamera(),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio:
                          1 / camera.value.aspectRatio, // auto calc correctly
                      child: CameraPreview(camera),
                    ),
                  ),
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
                          onVerticalDragUpdate: updateZoom,
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
            Positioned(
              top: MediaQuery.of(context).padding.top + 160, // safeBar + 100
              right: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(height: 34),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    opacity: showBloom ? 1.0 : 0.0, // Fades in/out
                    child: Text(
                      'Beautify: ${options['isBloom'] ? 'On' : 'Off'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 34),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    opacity: showFlash ? 1.0 : 0.0, // Fades in/out
                    child: Text(
                      'Flash: ${options['isFlash'] ? 'On' : 'Off'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(height: 34),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    opacity: showNoise ? 1.0 : 0.0, // Fades in/out
                    child: Text(
                      'Background noise: ${options['isNoise'] ? 'On' : 'Off'}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 160, // safeBar + 100
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                          onPressed: () => toggleBloom(),
                          child: SvgPicture.asset(
                            options['isBloom']
                                ? 'images/macro-on.svg'
                                : 'images/macro-off.svg',
                            height: 30,
                            width: 30,
                            colorFilter: ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                          onPressed: () => toggleFlash(),
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
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(12),
                          ),
                          onPressed: () => toggleNoise(),
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
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeBar(title: 'Poke~'),
            NavBar(dontOpen: 'cam'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    camera.dispose();
    ani.dispose();
    bloomBounce?.cancel();
    flashBounce?.cancel();
    noiseBounce?.cancel();
    super.dispose();
  }
}
