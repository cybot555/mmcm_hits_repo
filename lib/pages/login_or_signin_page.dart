import 'package:flutter/material.dart';
import 'package:mmcm_hits/pages/login_page.dart';
import 'package:mmcm_hits/pages/signup_page.dart';

class LoginOrSigninPage extends StatefulWidget {
  const LoginOrSigninPage({super.key});

  @override
  State<LoginOrSigninPage> createState() => _LoginOrSigninPageState();
}

class _LoginOrSigninPageState extends State<LoginOrSigninPage> {

  //intially show login page
  bool showLoginPage = true;

  //toggle between login and signin page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    }else{
      return SignupPage(
        onTap: togglePages,
      );
    }
  }
}