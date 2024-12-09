import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('위치 정보 업데이트 실패: $e');
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
      body: Center(
        child: _currentPosition != null
            ? Text(
                '현재 위치: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}')
            : const Text('위치 정보를 가져오는 중입니다...'),
      ),
    );
  }
}
