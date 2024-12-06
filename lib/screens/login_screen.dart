import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: "jd@pline.co.kr");
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendLoginLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url:
              'https://nesysworks.firebaseapp.com', // Firebase Console에 설정된 URL
          handleCodeInApp: true, // 앱 내부에서 인증 링크 처리
          androidPackageName: 'kr.plinemotors.nesysworks',
          androidInstallApp: true,
          androidMinimumVersion: '21', // 최소 Android 버전
          iOSBundleId: 'kr.plinemotors.nesysworks.nesysworks', // iOS 번들 ID
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login link sent to $email')),
      );

      // 이메일 저장 (필수)
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      print('Error sending login link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending login link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your email to log in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendLoginLink,
              child: Text('Send Login Link'),
            ),
          ],
        ),
      ),
    );
  }
}
