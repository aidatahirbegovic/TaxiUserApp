import 'package:flutter/material.dart';

class DrawerGestureDetector extends StatelessWidget {
  DrawerGestureDetector({this.icon, this.text, this.function});

  final icon;
  final text;
  final function;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.black,
        ),
        title: Text(
          text,
          style: TextStyle(fontSize: 15.0, color: Colors.black),
        ),
      ),
    );
  }
}
