import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';

import 'package:flouze/pages/welcome.dart';

void main() {
  //debugPaintSizeEnabled = true;
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flouze!',
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: new WelcomePage(),
    );
  }
}

