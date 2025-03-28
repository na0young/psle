import 'dart:io';

import 'package:flutter/material.dart';
import 'package:psle_app/screens/home_screen.dart';
import 'package:psle_app/services/api_service.dart';
import 'package:psle_app/services/firebase_messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final idController = TextEditingController();
  final passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  Future<void> _login() async {
    try {
      // 로그인 버튼 누르면 키보드 내리기
      FocusScope.of(context).unfocus();
      final user = await apiService.postUser(
        idController.text,
        passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id!);
      await prefs.setString('loginId', user.loginId!);
      await prefs.setString('password', user.password!);
      await prefs.setString('userName', user.name!);
      await prefs.setStringList('alarmTimes', user.alarmTimes ?? []);
      await prefs.setBool('isLoggedIn', true);

      // FCM 초기화, 토큰관리
      final FirebaseMessagingService fcmService = FirebaseMessagingService();
      await fcmService.initialize();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on SocketException {
      _showSnackBar("서버에 연결할 수 없습니다. 나중에 다시 시도해주세요.");
    } on HttpException {
      _showSnackBar("아이디 또는 비밀번호가 올바르지 않습니다. ");
    } catch (e) {
      _showSnackBar("로그인 중 오류가 발생하였습니다. 다시 시도해주세요.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color.fromARGB(255, 255, 111, 111),
        elevation: 0,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PSLE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '정서 반복 기록 알림',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: idController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                labelText: 'ID',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                labelText: 'Password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 111, 111),
                ),
                onPressed: _login,
                child: const Text(
                  '로그인',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }
}
