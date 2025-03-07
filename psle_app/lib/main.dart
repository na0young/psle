import 'package:flutter/material.dart';
import 'package:psle_app/screens/home_screen.dart';
import 'package:psle_app/screens/login_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  // 비동기 작업들을 초기화 하기 위해 Flutter 프레임워크 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 및 타임존 초기화
  await Firebase.initializeApp(); // Firebase Core 초기화
  tz.initializeTimeZones();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSLE',
      navigatorKey: navigatorKey,
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data == true) {
              return const HomeScreen();
            } else {
              return const LoginScreen();
            }
          }
        },
      ),
      //debugShowCheckedModeBanner: false,
    );
  }
}
