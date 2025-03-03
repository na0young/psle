import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class User {
  int? id; // 사용자 식별 아이디
  String? loginId; // 사용자 로그인 아이디
  String? password; // 사용자 로그인 비밀번호
  String? name; // 사용자 이름
  List<String>? alarmTimes; // 알람시간 목록

  User({this.id, this.loginId, this.password, this.name, this.alarmTimes});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      loginId: json['loginId'],
      password: json['password'],
      name: json['name'],
      alarmTimes: json['esmAlarms'] != null
          ? List<String>.from(json['esmAlarms'])
          : ['9:00:00', '12:00:00', '15:00:00', '18:08:00'], // API 통신 실패시 디폴트값
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "loginId": loginId,
        "password": password,
        "name": name,
        "alarmTimes": alarmTimes,
      };

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // sharedPreference에서 토큰 가져오기
    String? fcmToken = prefs.getString('fcmToken');
    int? userId = prefs.getInt('id');
    // 서버에서 FCM 토큰 삭제
    if (fcmToken != null && userId != null) {
      await deleteTokenFromServer(userId, fcmToken);
    }
    // Firebase에서 FCM 토큰 삭제
    await FirebaseMessaging.instance.deleteToken();

    // 로그아웃을 위한 앱내변수 삭제
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('loginId');
    await prefs.remove('password');
    await prefs.remove('id');
    await prefs.remove('name');
    await prefs.remove('lastRecordTime');
    await prefs.remove('fcmToken');
    loginId = null;
    password = null;
  }

  Future<void> deleteTokenFromServer(int userId, String fcmToken) async {
    final url =
        Uri.parse("http://210.125.94.106:8080/PSLE-0.0.1-SNAPSHOT/deleteToken");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('FCM 토큰 삭제 성공');
      } else {
        print('FCM 토큰 삭제 실패: ${response.body}');
      }
    } catch (e) {
      print('FCM 토큰 삭제 중 오류 발생: $e');
    }
  }
}
