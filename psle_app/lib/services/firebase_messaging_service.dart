import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psle_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:psle_app/screens/webview_screen.dart';
import 'package:psle_app/screens/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  final Logger _logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // FCM 초기화 및 토큰 가져오기
  Future<void> initialize() async {
    // 알림 권한 요청 (iOS의 경우 필수)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('FCM 권한 허용됨');

      // FCM 토큰 가져오기
      String? newToken = await _firebaseMessaging.getToken();
      if (newToken != null) {
        _logger.i('FCM 토큰: $newToken');

        // SharedPreference와 비교, 저장
        await _syncTokenWithServer(newToken);
      } else {
        _logger.w('FCM 토큰 발급 실패.');
      }
    } else {
      _logger.i('FCM 권한 거부됨');
    }
    // 푸시 알림 클릭 시 특정 페이지로 이동
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i("알림 클릭됨!");
      _handleNotificationClick();
    });

    // 앱이 종료된 상태에서 푸시 알림을 눌러 실행한 경우
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logger.i("앱 종료 상태에서 알림 클릭됨!");
      _handleNotificationClick();
    }
  }

  // SharedPreference 및 서버 동기화
  Future<void> _syncTokenWithServer(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('fcmToken');
    int? userId = prefs.getInt('userId'); // 로그인 시 저장된 userId

    if (userId == null) {
      _logger.w('SharedPreferences에 userId가 없음. 토큰을 서버로 보낼 수 없습니다.');
      return;
    }

    // 기존 토큰이 없음
    if (oldToken == null) {
      _logger.i("기존 토큰이 없습니다. 새 기기에서 FCM 토큰 저장");
      await prefs.setString('fcmToken', newToken);
      // 서버로 전송
      await _sendTokenToServer(newToken, userId);
    }
    // 기존 토큰과 앱진입시 발급받은 토큰이 다름.
    else if (oldToken != newToken) {
      _logger.i('토큰 변경 감지. 서버에서 이전 토큰 삭제 후 새 토큰 저장.');
      // SharedPreferences에 저장
      await deleteTokenFromServer(oldToken, userId);
      await prefs.setString('fcmToken', newToken);
      await _sendTokenToServer(newToken, userId);
    }
    // 기존 토큰과 앱진입시 발급받은 토큰이 다름.
    else {
      _logger.i('기존 토큰과 동일. 서버 전송 생략.');
    }
  }

  // 서버에서 특정 토큰 삭제
  Future<void> deleteTokenFromServer(String token, int userId) async {
    final Logger _logger = Logger();
    try {
      final url = Uri.parse(
          "http://210.125.94.106:8080/PSLE-0.0.1-SNAPSHOT/deleteToken");
      _logger.i("서버에 FCM 토큰 삭제 요청 보냄: userId = $userId, fcmToken = $token");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('FCM 토큰 삭제 성공: ${response.body}');
      } else {
        _logger.e('FCM 토큰 삭제 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _logger.e('FCM 토큰 삭제 중 오류 발생: $e');
    }
  }

// 서버로 토큰 전송
  Future<void> _sendTokenToServer(String token, int userId) async {
    try {
      final url =
          Uri.parse("http://210.125.94.106:8080/PSLE-0.0.1-SNAPSHOT/saveToken");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'userId': userId,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('FCM 토큰 서버 전송 성공: ${response.body}');
      } else {
        _logger.e('FCM 토큰 서버 전송 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _logger.e('FCM 토큰 서버 전송 중 오류 발생: $e');
    }
  }

  void _handleNotificationClick() {
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (navigatorKey.currentState != null) {
        if (isLoggedIn) {
          _logger.i("로그인 상태 확인됨 → WebviewScreen으로 이동");
          navigatorKey.currentState!
              .push(MaterialPageRoute(builder: (_) => const WebviewScreen()));
        } else {
          _logger.i("로그인 필요 → LoginScreen으로 이동");
          navigatorKey.currentState!
              .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        _logger.w("navigatorKey.currentState가 null입니다. 화면 이동 불가.");
      }
    });
  }
}
