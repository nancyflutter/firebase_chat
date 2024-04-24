import 'package:flutter/material.dart';

class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff363636),
      body: Center(
        child: Text(
          "Online",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
