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

  void updateTheme(ThemeMode newMode) {
    setState(() {
      _mode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M-PESA Smart Calc KE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF2F8F2),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF00A651), foregroundColor: Colors.white),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1A1A1A), foregroundColor: Colors.white),
        cardColor: Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      themeMode: _mode,
      home: MainScreen(currentMode: _mode, onModeChanged: updateTheme),
    );
  }
}
