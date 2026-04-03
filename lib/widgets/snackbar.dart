import 'package:flutter/material.dart';

void _show(String msg, BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}