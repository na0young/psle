import 'package:flutter/material.dart';
import 'package:psle_app/screens/webview_screen.dart';
import 'package:psle_app/screens/login_screen.dart';
import 'package:psle_app/services/api_service.dart';
import 'package:psle_app/services/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger();
  final FirebaseMessagingService fcmService = FirebaseMessagingService();

  String userName = '';
  String lastRecordTime = '최근 기록 없음';
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastRecordTime();
    fcmService.initialize();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '사용자';
    });
  }

  Future<void> _loadLastRecordTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId != null) {
        final esmTestLog = await apiService.postEsmTestLog(userId);
        setState(() {
          lastRecordTime = '${esmTestLog.date} ${esmTestLog.time}';
        });
      } else {
        setState(() {
          lastRecordTime = '최근 기록 없음';
        });
      }
    } catch (e) {
      setState(() {
        lastRecordTime = '최근 기록 없음';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final FirebaseMessagingService fcmService = FirebaseMessagingService();
    // 1. FCM 토큰 가져오기
    // sharedPreference에서 토큰 가져오기
    String? fcmToken = prefs.getString('fcmToken');
    int? userId = prefs.getInt('userId');

    // 서버에서 FCM 토큰 삭제
    if (fcmToken != null && userId != null) {
      await fcmService.deleteTokenFromServer(fcmToken, userId);
    }
    // 2. Firebase에서 FCM 토큰 삭제
    await FirebaseMessaging.instance.deleteToken();
    // 3. SharedPreference 데이터 삭제
    await prefs.clear();
    _logger.i('사용자 로그아웃 완료');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              Text(
                '$userName님',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 111, 111)),
                onPressed: _logout,
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80), // AppBar와 Box 사이 간격
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15), // 정서 반복 기록 Text위 여백
                  const Text(
                    '정서 반복 기록',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10), // 정서 반복 기록 과 최근 기록 시간 사이 여백
                  Text(
                    '최근 기록 시간 : $lastRecordTime',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 61, 61, 61),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 15), // 최근 기록 시간 Text 밑 여백
                ],
              ),
            ),
            const SizedBox(height: 100), // Box와 기록하러가기 버튼 사이 여백
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 111, 111),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    )),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WebviewScreen()),
                  );
                  //webview에서 반환한 갱신 플래그가 true -> 기록 시간 갱신
                  if (result == true) {
                    await _loadLastRecordTime();
                  }
                },
                child: const Text(
                  '기록하러 가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
