import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late final WebViewController controller; // WebViewController 선언
  String? userId;
  String? userPw;

  @override
  void initState() {
    super.initState();
    // WebViewController 초기화
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            print('WebView error: ${error.description}');
          },
        ),
      );

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('loginId');
    final pw = prefs.getString('password');

    if (id != null && pw != null) {
      setState(() {
        userId = id;
        userPw = pw;
      });
      // URL 로드
      controller.loadRequest(
        Uri.parse(
            'http://210.125.94.106:8080/PSLE-0.0.1-SNAPSHOT/doLogin?userid=$userId&userpw=$userPw'),
      );
    } else {
      setState(() {
        userId = null;
        userPw = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || userPw == null) {
      return const Scaffold(
        body: Center(
          child: Text('오류: 사용자 정보가 누락되었습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '정서 반복 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
