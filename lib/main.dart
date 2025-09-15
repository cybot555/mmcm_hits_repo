import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/login_page.dart';

//CYRUS GLENN L. DIGAL PRINCE KURT G. CAGAS TEST COMMIT FOR PUSH (TO SHOW CHANGE)
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}
