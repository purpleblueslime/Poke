import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import './components/call_api.dart';

class UserPro with ChangeNotifier {
  late SharedPreferences shared;
  late FlutterSecureStorage secure;
  dynamic _user;
  dynamic _token;
  Map<String, bool> _options = {};
  dynamic _fcmToken;

  dynamic get user => _user;
  dynamic get token => _token;
  dynamic get options => _options;
  dynamic get fcmToken => _fcmToken;

  dynamic init() async {
    await Firebase.initializeApp();
    shared = await SharedPreferences.getInstance();
    secure = FlutterSecureStorage();

    dynamic userJson = shared.getString('user');
    if (userJson != null) {
      dynamic map = json.decode(userJson);
      _user = map;
    }

    dynamic optionsJson = shared.getString('options');
    if (optionsJson != null) {
      dynamic map = json.decode(optionsJson);
      _options = Map<String, bool>.from(map);
    } else {
      await setOptions({'isFlash': false, 'isNoise': true, 'isGeo': true});
    }

    dynamic token = await secure.read(key: 'token');
    if (token != null) {
      _token = token;
    }

    dynamic fcmToken = await secure.read(key: 'fcmToken');
    if (fcmToken != null) {
      _fcmToken = fcmToken;
    }

    if (isLoggedIn && fcmToken == null) {
      setFcmToken();
    }

    notifyListeners();
  }

  dynamic setUser(dynamic user) async {
    _user = user;
    await shared.setString('user', json.encode(user));
    notifyListeners();
  }

  dynamic setOptions(Map<String, bool> update) async {
    _options.addAll(update); // map <some stringgg and a tru/fal>
    await shared.setString('options', json.encode(_options));
    notifyListeners();
  }

  dynamic setToken(dynamic token) async {
    _token = token;
    await secure.write(key: 'token', value: token);
    notifyListeners();
  }

  dynamic delete() async {
    // dont delete user otherwise everything fucks up
    // _user = null;
    _token = null;
    _fcmToken = null;
    // await shared.remove('user');
    await secure.delete(key: 'token');
    await secure.delete(key: 'fcmToken');
    notifyListeners();
  }

  dynamic refresh() async {
    dynamic re = await g('/me', _token);

    if (re.statusCode == 401) {
      await delete();
      return;
    }

    if (re.statusCode != 200) {
      return;
    }

    await shared.setString('user', re.body);
    _user = json.decode(re.body);
    notifyListeners();
  }

  dynamic setFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      dynamic fcm = await messaging.getToken();

      if (fcm == null) {
        return; // fcm denied by user
      }

      dynamic re = await p('/me/fcm', {'fcmToken': fcm}, _token);

      if (re.statusCode == 401) {
        await delete();
        return;
      }

      if (re.statusCode != 200) {
        return;
      }

      await secure.write(key: 'fcmToken', value: fcm);
    } catch (e) {
      return;
    }
    notifyListeners();
  }

  dynamic get isLoggedIn => _token != null;
}
