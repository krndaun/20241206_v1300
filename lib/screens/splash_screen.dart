import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Timer to navigate to the login screen after 3 seconds
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, Routes.login);
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
