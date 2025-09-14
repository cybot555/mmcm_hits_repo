import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: false,
      ),
    );
  }
}
