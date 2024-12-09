import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    try {
      await _requestPermission();
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
      print('위치 권한 거부됨');
    } else if (status.isPermanentlyDenied) {
      print('위치 권한 영구적으로 거부됨');
      openAppSettings(); // 사용자에게 설정 화면을 열도록 요청
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
