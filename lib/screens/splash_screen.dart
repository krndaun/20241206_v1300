import 'dart:convert'; // jsonEncode를 위한 import

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http; // HTTP 요청을 위한 import
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _initializePermissions();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initializePermissions() async {
    try {
      await _requestPermission();
      await _initializeFirebaseMessaging();
      _navigateToNextScreen();
    } catch (e) {
      print('권한 요청 중 오류 발생: $e');
      _navigateToNextScreen(); // 권한이 없어도 앱을 계속 실행할 수 있도록 처리
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      print('위치 권한 허용됨');
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요.')),
      );
      print('위치 권한 거부됨');
    } else if (status.isPermanentlyDenied) {
      print('위치 권한 영구적으로 거부됨');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.'),
          action: SnackBarAction(
            label: '설정 열기',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('알림 권한 허용됨');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('임시 알림 권한 허용됨');
    } else {
      print('알림 권한 거부됨');
      return;
    }

    String? token = await messaging.getToken();
    if (token != null) {
      print('FCM 토큰: $token');
      try {
        final response = await http.post(
          Uri.parse('https://works.plinemotors.kr/api/save-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fcm_token': token}),
        );

        if (response.statusCode == 200) {
          print('토큰 전송 성공');
        } else {
          print('토큰 전송 실패: ${response.body}');
        }
      } catch (e) {
        print('FCM 토큰 전송 중 오류 발생: $e');
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 푸시 알림 수신: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('푸시 알림으로 앱 열림: ${message.notification?.title}');
      Navigator.pushNamed(context, '/home');
    });
  }

  void _navigateToNextScreen() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Image.asset(
            'assets/images/splash_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
