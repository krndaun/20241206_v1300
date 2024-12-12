import 'dart:convert'; // JSON 인코딩/디코딩

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  String? _currentAddress;
  Map<String, dynamic>? _currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _listenToUserInfo(user.uid);
      _updateLocation();
    }
  }

  void _listenToUserInfo(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _currentUser = snapshot.data() as Map<String, dynamic>;
        });
      }
    });
  }

  Future<void> _updateLocation() async {
    try {
      // 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }

      // 위치 서비스 활성화 여부 확인
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다.');
      }

      // 위치 정보 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      print('현재 위치: $_currentPosition');

      // 주소 변환
      final address =
          await _getAddressFromLatLng(position.latitude, position.longitude);

      // Firestore에 위치 정보 저장
      await _saveOrUpdateLocation(position, address);

      // 서버로 위치 정보 및 FCM 토큰 전송
      await _sendLocationToServer(position, address);
    } catch (e) {
      print('위치 정보 업데이트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보를 가져오는 데 실패했습니다. 오류: $e')),
      );
    }
  }

  Future<void> _sendLocationToServer(Position position, String? address) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('사용자가 인증되지 않았습니다.');
      return;
    }

    String? token = await FirebaseMessaging.instance.getToken();

    if (token == null) {
      print('FCM 토큰을 가져올 수 없습니다.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://works.plinemotors.kr/api/save-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': token,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address ?? '주소 없음',
          'email': currentUser.email,
          'userid': currentUser.uid,
        }),
      );

      if (response.statusCode == 200) {
        print('위치 정보 및 FCM 토큰 전송 성공');
      } else {
        print('위치 정보 및 FCM 토큰 전송 실패: ${response.body}');
      }
    } catch (e) {
      print('위치 정보 및 FCM 토큰 전송 중 오류 발생: $e');
    }
  }

  Future<String?> _getAddressFromLatLng(
      double latitude, double longitude) async {
    const String kakaoApiKey =
        '96a29c4e8f07bac64ccb6133dd98c006'; // 카카오 REST API 키
    final String url =
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$longitude&y=$latitude';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK $kakaoApiKey'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final address = data['documents'][0]['address']['address_name'];
          print('카카오 주소 변환 성공: $address');
          setState(() {
            _currentAddress = address; // 주소를 상태 변수에 저장
          });
          return address;
        } else {
          print('카카오 API로 주소를 찾을 수 없습니다.');
          return null;
        }
      } else {
        print('카카오 API 요청 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('카카오 주소 변환 실패: $e');
      return null;
    }
  }

  Future<void> _saveOrUpdateLocation(Position position, String? address) async {
    final user = _auth.currentUser;

    if (user == null) {
      print('사용자가 인증되지 않았습니다.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address ?? '주소 없음',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      print('Firestore 위치 정보 저장/업데이트 성공');
    } catch (e) {
      print('Firestore 저장 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentUser?['username'] ?? '홈'),
      ),
      drawer: CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _updateLocation,
        child: ListView(
          children: [
            Center(
              child: _currentPosition != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentAddress != null) Text('$_currentAddress'),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
