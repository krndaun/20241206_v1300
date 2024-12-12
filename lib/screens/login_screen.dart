import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: "jd@pline.co.kr"); // 기본 이메일
  final TextEditingController _passwordController =
      TextEditingController(text: "password123"); // 기본 비밀번호
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일과 비밀번호를 입력해주세요.')),
      );
      return;
    }

    try {
      UserCredential userCredential;

      // Firebase 이메일/비밀번호로 로그인 시도
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('로그인 성공: ${userCredential.user!.uid}');
      } catch (e) {
        // 로그인 실패 시 계정 생성
        print('로그인 실패, 새 계정 생성 시도: $e');
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('새 계정 생성 성공: ${userCredential.user!.uid}');
      }

      final uid = userCredential.user!.uid;
      _sendToApi(uid, email); // API 호출
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  Future<void> _sendToApi(String uid, String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://works.plinemotors.kr/apilogin'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          final userData = data['username'];

          // Firestore에 사용자 정보 저장 또는 업데이트
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'id': userData['id'],
            'username': userData['username'],
            'teamsid': userData['teamsid'],
            'pdiv': userData['pdiv'],
            'cdiv': userData['cdiv'],
            'ast_admin': userData['ast_admin'],
            'dash_mode': userData['dash_mode'],
            'team': userData['team'],
            'dept': userData['dept'],
            'dpt': userData['dpt'],
            'dept2': userData['dept2'],
            'logkey': userData['logkey'],
            'atv': userData['atv'],
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // 기존 데이터 병합

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('환영합니다, ${userData['username']}님!')),
          );

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API 로그인 실패: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 오류: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('API 호출 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 호출 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
