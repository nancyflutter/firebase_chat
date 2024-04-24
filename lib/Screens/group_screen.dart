import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff363636),
      body: Center(
        child: Text("Group",style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
