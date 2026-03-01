import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import './user_provider.dart';
import './pages/cam.dart';
import './pages/log_in.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    // syst ui changes on some devices
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );

  final usr = UserPro();
  await usr.init();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    usr.refresh();
  });

  runApp(ChangeNotifierProvider(create: (_) => usr, child: App()));

  if (!usr.isLoggedIn) return; // no refresh if no user
  await usr.refresh(); // start app with a refresh
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _App();
}

class _App extends State<App> with WidgetsBindingObserver {
  late UserPro usr;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Obtain UserPro without listening (avoid rebuild)
    usr = Provider.of(context, listen: false);
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!usr.isLoggedIn) return; // no refresh if no user

    usr.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // listen to logout gracefully (we dont care about logout we just remove token)
    dynamic usrListen = Provider.of<UserPro>(context);
    Color tealColor = Color(0xff7ceece);

    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xff111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
          ),
          contentPadding: EdgeInsets.all(16.0),
        ),
        buttonTheme: ButtonThemeData(buttonColor: tealColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tealColor,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900),
          ),
        ),
      ),
      home: usrListen.isLoggedIn ? Cam() : LogIn(),
    );
  }
}
