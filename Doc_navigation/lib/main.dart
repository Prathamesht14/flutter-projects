import 'package:flutter/material.dart';
import 'screens/leaflet_live.dart';

void main() {
  runApp(const DRDSApp());
}

class DRDSApp extends StatelessWidget {
  const DRDSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRDS - Live Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LeafletLive(), // ✅ REMOVED const here
    );
  }
}
