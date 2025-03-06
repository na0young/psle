import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:psle_app/models/user.dart';
import 'package:psle_app/models/esm_test_log.dart';

class ApiService {
  final dio = Dio(BaseOptions(
      baseUrl: 'http://210.125.94.106:8080/PSLE-0.0.1-SNAPSHOT/',
      headers: {
        "Content-Type": "application/json;charset=UTF-8",
        "Accept": "application/json",
      },
      validateStatus: ((status) {
        return status! < 500;
      })));

  /* -- POST /user */
  Future<User> postUser(String loginIdInput, String passwordInput) async {
    // body data
    Map data = {
      'loginId': loginIdInput,
      "password": passwordInput,
    };

    // encode Map to JSON
    var body = jsonEncode(data);

    var response = await dio.post('/user', data: body);

    int? code = response.statusCode;
    String message = response.data["message"];
    Map<String, dynamic> responseData = response.data["user"];

    // 서버 응답에서 알람시간 추출
    List<String> alarmTimes = response.data["esmAlarms"]?.cast<String>();
    User user = User.fromJson(responseData);
    // 수정전 아래 if문은 없었음(추후 참고)
    // 서버 응답에서 알람시간 추출 후 User 객체에 할당
    if (response.data['esmAlarms'] != null) {
      user.alarmTimes = List<String>.from(response.data['esmAlarms']);
    }

    /* DEBUG CONSOLE 확인*/
    debugPrint("-- POST /user");
    debugPrint("code : ${code.toString()}");
    debugPrint("message : $message");
    debugPrint("userLoginId : ${user.loginId}");
    debugPrint("userPassword : ${user.password}");
    debugPrint("alarmTimes : $alarmTimes");

    return user;
  }

  /* -- POST /esmTestLog */
  Future<EsmTestLog> postEsmTestLog(int id) async {
    // body data
    Map data = {"id": id};

    // encode Map to JSON
    var body = jsonEncode(data);

    var response = await dio.post('/esmTestLog', data: body);

    int? code = response.statusCode;
    String message = response.data["message"];
    Map<String, dynamic> responseData = response.data["esmTestLog"];

    EsmTestLog esmTestLog = EsmTestLog.fromJson(responseData);

    /* DEBUG CONSOLE 확인*/
    debugPrint("-- POST /esmTestLog");
    debugPrint("code : ${code.toString()}");
    debugPrint("message : $message");
    debugPrint(esmTestLog.date);
    debugPrint(esmTestLog.time);
    return esmTestLog;
  }

  Future<DateTime?> getLastRecordDateTime(int userId) async {
    EsmTestLog esmTestLog = await postEsmTestLog(userId);
    if (esmTestLog.date != null && esmTestLog.time != null) {
      try {
        return DateTime.parse('${esmTestLog.date} ${esmTestLog.time}');
      } catch (e) {
        debugPrint('Error parsing DateTime: $e');
      }
    }
    return null;
  }
}
