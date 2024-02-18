import 'package:flutter/material.dart';
import 'package:gps_tracking/location.dart';
// import 'package:gps_tracking/timer.dart';
// import 'package:gps_tracking/test.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(methodCount: 0),
);
// Main Function
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GPS Tracker',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: const LocationPage(),
      // home: MyHomePage(),
    );
  }
}
