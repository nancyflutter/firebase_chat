import 'package:flutter/material.dart';

InputDecoration textFieldDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Colors.white),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.teal),
    ),
  );
}

TextStyle textStyleForTextField() {
  return const TextStyle(color: Colors.teal);
}

TextStyle textStyle() {
  return const TextStyle(
    color: Colors.teal,
    decoration: TextDecoration.underline,
    decorationColor: Colors.tealAccent,
    decorationThickness: 1,
  );
}
