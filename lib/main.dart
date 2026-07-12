import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(MpesaSmartCalcApp());
}

class MpesaSmartCalcApp extends StatefulWidget {
  @override
  State<MpesaSmartCalcApp> createState() => _MpesaSmartCalcAppState();
}

class _MpesaSmartCalcAppState extends State<MpesaSmartCalcApp> {
  ThemeMode _mode = ThemeMode.system;
  void updateTheme(ThemeMode m) => setState(() => _mode = m);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(primarySwatch: Colors.green, brightness: Brightness.dark, useMaterial3: true),
      themeMode: _mode,
      home: MainScreen(currentMode: _mode, onModeChanged: updateTheme),
    );
  }
}
