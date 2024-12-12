import 'dart:convert'; // JSON 인코딩/디코딩

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
      await _requestLocationPermission();
      await _initializeFirebaseMessaging();
      _navigateToNextScreen();
    } catch (e) {
      print('권한 요청 중 오류 발생: $e');
      _navigateToNextScreen();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      print('위치 권한 허용됨');
    } else if (status.isDenied || status.isPermanentlyDenied) {
      print('위치 권한 거부됨');
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
    } else {
      print('알림 권한 거부됨');
      return;
    }

    String? token = await messaging.getToken();
    User? currentUser = FirebaseAuth.instance.currentUser; // 현재 사용자 가져오기

    if (token != null && currentUser != null) {
      print('FCM 토큰: $token');
      print('현재 사용자 UID: ${currentUser.uid}');
      print('현재 사용자 이메일: ${currentUser.email}');

      Position? position = await _getCurrentLocation();
      String? address = await _getAddressFromCoordinates(position);

      try {
        // 서버로 FCM 토큰 및 위치 정보 전송
        final response = await http.post(
          Uri.parse('https://works.plinemotors.kr/api/save-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fcm_token': token,
            'latitude': position?.latitude,
            'longitude': position?.longitude,
            'address': address,
            'email': currentUser.email,
            'userid': currentUser.uid,
          }),
        );

        if (response.statusCode == 200) {
          print('토큰 전송 성공');
        } else {
          print('토큰 전송 실패: ${response.body}');
        }
      } catch (e) {
        print('FCM 토큰 전송 중 오류 발생: $e');
      }
    } else {
      print('FCM 토큰을 가져올 수 없습니다.');
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
      Navigator.pushNamed(context, '/home');
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('위치 정보 가져오기 실패: $e');
      return null;
    }
  }

  Future<String?> _getAddressFromCoordinates(Position? position) async {
    if (position == null) return null;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.first;
      return '${placemark.locality}, ${placemark.subLocality}, ${placemark.thoroughfare}';
    } catch (e) {
      print('주소 변환 실패: $e');
      return null;
    }
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
