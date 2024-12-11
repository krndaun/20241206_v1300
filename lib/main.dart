import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/routes.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 백그라운드 메시지 처리
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 푸시 알림 수신: ${message.notification?.title}');
}

// 로컬 알림 초기화
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      try {
        print('알림 응답: ${response.payload}');
        if (response.payload != null) {
          navigatorKey.currentState?.pushNamed('/home');
        }
      } catch (e) {
        print('알림 클릭 이벤트 처리 중 오류 발생: $e');
      }
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 로컬 알림 초기화
  await initializeLocalNotifications();

  // 백그라운드 메시지 핸들러 등록
  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      print('백그라운드 푸시 알림 수신: ${message.notification?.title}');
    } catch (e) {
      print('백그라운드 메시지 처리 중 오류 발생: $e');
    }
  }

  // FirebaseMessaging 설정
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 알림 권한 요청 (iOS)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // APNs 토큰 가져오기
  String? apnsToken = await messaging.getAPNSToken();
  print('APNs Token: $apnsToken');

  // FCM 토큰 가져오기
  String? fcmToken = await messaging.getToken();
  print('FCM Token: $fcmToken');

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('알림 권한 허용됨');
  } else {
    print('알림 권한 거부됨');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    try {
      print('포그라운드 푸시 알림 수신: ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        final title = notification.title ?? '제목 없음';
        final body = notification.body ?? '내용 없음';
        print('알림 제목: $title, 내용: $body');

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              channelDescription: 'channel_description',
              importance: Importance.high,
            ),
          ),
        );
      }
    } catch (e) {
      print('포그라운드 메시지 처리 오류: $e');
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    try {
      print('푸시 알림 클릭 후 열림: ${message.notification?.title}');
      navigatorKey.currentState?.pushNamed('/home');
    } catch (e) {
      print('알림 클릭 처리 중 오류 발생: $e');
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'nesysworks',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => SplashScreen(),
        Routes.login: (context) => LoginScreen(),
        Routes.home: (context) => HomeScreen(),
      },
    );
  }
}
