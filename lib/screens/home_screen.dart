import 'dart:convert'; // JSON 인코딩/디코딩

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // HTTP 요청

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  String? _currentAddress; // 주소 저장
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase 인증

  @override
  void initState() {
    super.initState();
    _updateLocation();
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
          throw Exception('위치 권한이 거부되었습니다. 설정에서 위치 권한을 활성화해주세요.');
        }
      }

      // 위치 서비스 활성화 여부 확인
      bool isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.');
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
      await _getAddressFromLatLng(position.latitude, position.longitude);

      // Firestore에 위치 정보 저장
      await _saveLocationToFirestore(position);
    } catch (e) {
      print('위치 정보 업데이트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보를 가져오는 데 실패했습니다. 오류: $e')),
      );
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      Placemark place = placemarks.first;

      setState(() {
        _currentAddress =
            '${place.locality}, ${place.subLocality}, ${place.thoroughfare}';
      });

      print('주소 변환 성공: $_currentAddress');
    } catch (e) {
      print('주소 변환 실패: $e');
    }
  }

  Future<void> _saveLocationToFirestore(Position position) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('사용자가 인증되지 않았습니다.');
        return;
      }

      // Firestore에 위치 정보 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': _currentAddress,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      print(
          '위치 정보 Firestore에 저장됨: ${position.latitude}, ${position.longitude}');

      // Firestore 업데이트 후 FCM 알림 전송
      await _sendPushNotification(
        title: '위치 업데이트됨',
        body: '새로운 위치: $_currentAddress',
      );
    } catch (e) {
      print('Firestore 업데이트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보를 Firestore에 저장하는 데 실패했습니다.')),
      );
    }
  }

  Future<void> _sendPushNotification({
    required String title,
    required String body,
  }) async {
    const String serverKey =
        'TDsqJ7tBQLL9xAn7yD5svpgmeBYuizdTe8_UfqD4LXg'; // Firebase 서버 키
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    // FCM 토큰 (테스트용으로 사용자의 토큰 또는 구독 토픽 사용)
    const String userToken = 'USER_DEVICE_FCM_TOKEN';

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': userToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'message': body,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('푸시 알림 전송 성공');
      } else {
        print('푸시 알림 전송 실패: ${response.body}');
      }
    } catch (e) {
      print('푸시 알림 전송 중 오류 발생: $e');
    }
  }

  Future<void> _refreshLocation() async {
    if (_currentPosition == null) {
      await _updateLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보가 이미 최신 상태입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                '메뉴',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('위치 새로고침'),
              onTap: _updateLocation,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLocation,
        child: ListView(
          children: [
            Center(
              child: _currentPosition != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            '현재 위치: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
                        if (_currentAddress != null)
                          Text('주소: $_currentAddress'),
                      ],
                    )
                  : const Text('위치 정보를 가져오는 중입니다...'),
            ),
          ],
        ),
      ),
    );
  }
}
