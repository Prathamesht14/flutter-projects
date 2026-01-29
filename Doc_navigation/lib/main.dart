import 'package:flutter/material.dart';
import 'screens/leaflet_live.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LeafletLiveTrackingPage(),
    );
  }
}
