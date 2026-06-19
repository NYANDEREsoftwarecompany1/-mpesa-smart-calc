import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(MpesaSmartCalcApp());
}

class MpesaSmartCalcApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M-Pesa Smart Calc KE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF00B140),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        fontFamily: 'Roboto',
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  int? _inputAmount;
  int? _resultAmount;
  int? _lostAmount;
  int _totalSavings = 0;
  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadHistory();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalSavings = prefs.getInt('savings')?? 0);
  }

  Future<void> _saveMoney(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    _totalSavings += amount;
    await prefs.setInt('savings', _totalSavings);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved KSh $amount! Total: KSh $_totalSavings'), backgroundColor: Colors.blue[700], duration: Duration(seconds: 2)),
    );
  }

  Future<void> _withdrawSavings() async {
    if (_totalSavings < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save at least KSh 50 first'), backgroundColor: Colors.orange),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw KSh $_totalSavings?'),
        content: Text('1. Go to M-Pesa app\n2. Withdraw KSh $_totalSavings cash\n3. Tap "Yes" below\nJar will reset to 0'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('savings', 0);
              setState(() => _totalSavings = 0);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🎉 Withdrawn! Jar reset to 0. Spend wisely bro'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00B140)),
            child: Text('Yes, I withdrew', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('history')?? '[]';
    setState(() => _history = List<Map<String, dynamic>>.from(json.decode(historyJson)));
  }

  Future<void> _saveHistory(int input, int result, int lost) async {
    final prefs = await SharedPreferences.getInstance();
    final newEntry = {'input': input, 'result': result, 'lost': lost, 'time': DateTime.now().toIso8601String()};
    _history.insert(0, newEntry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setString('history', json.encode(_history));
  }

  int _calculateMpesaAmount(int amount) {
    if (amount <= 49) return 50;
    if (amount % 10 == 0) return amount;
    return ((amount / 10).ceil()) * 10;
  }

  void _calculate() {
    final input = int.tryParse(_controller.text);
    if (input == null || input <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter valid amount'), backgroundColor: Colors.red));
      return;
    }
    final result = _calculateMpesaAmount(input);
    final lost = result - input;
    setState(() {
      _inputAmount = input;
      _resultAmount = result;
      _lostAmount = lost;
    });
    _saveHistory(input, result, lost);
  }

  void _copyToClipboard() {
    if (_resultAmount == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KSh $_resultAmount copied! Paste in M-Pesa'), backgroundColor: Colors.green));
  }

  void _shareResult() {
    if (_inputAmount == null || _resultAmount == null || _lostAmount == null) return;
    const playStoreLink = 'https://play.google.com/store/apps/details?id=com.yourname.mpesasmartcalc';
    final text = '''M-Pesa Smart Calc KE 📱
Nilitaka kutuma: KSh $_inputAmount
Lazima nitume: KSh $_resultAmount
Nimepoteza: KSh $_lostAmount bob

Agent hana lawama - Safaricom hu-round kwa 10!
Download app hapa bure: $playStoreLink''';
    Share.share(text, subject: 'Stop losing bob to M-Pesa rounding');
  }

  @override
  void dispose() {
    _controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('M-Pesa Smart Calc KE', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF00B140), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
              child: Column(
                children: [
                  Text('Enter Amount You Want to Send', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'KSh ',
                      prefixStyle: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF00B140)),
                      hintText: '237',
                      hintStyle: TextStyle(fontSize: 42, color: Colors.grey[300]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF00B140), width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF00B140), width: 3)),
                      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      child: Text('CALCULATE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00B140), padding: EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
            if (_resultAmount!= null)...[
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00B140), width: 2), boxShadow: [BoxShadow(color: Color(0xFF00B140).withOpacity(0.2), blurRadius: 15, offset: Offset(0, 6))]),
                child: Column(
                  children: [
                    Text('Send This Amount', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 8),
                    Text('KSh $_resultAmount', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Color(0xFF00B140))),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                      child: Text('You lose: $_lostAmount bob', style: TextStyle(fontSize: 18, color: Colors.red[700], fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 6), Text('Agent is right', style: TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w600))]),
                    SizedBox(height: 8),
                    Text('Note: Safaricom rounds all amounts to nearest 10. Agent has no choice.', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: Icon(Icons.copy, size: 18),
                            label: Text('COPY', style: TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00B140), padding: EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareResult,
                            icon: Icon(Icons.share, size: 18, color: Color(0xFF00B140)),
                            label: Text('SHARE', style: TextStyle(fontSize: 14, color: Color(0xFF00B140))),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: Color(0xFF00B140)), padding: EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    if (_lostAmount!= null && _lostAmount! > 0)...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue[200]!)),
                        child: Column(
                          children: [
                            Text('My Savings Jar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                            SizedBox(height: 8),
                            Text('KSh $_totalSavings', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _saveMoney(_lostAmount!),
                                    icon: Icon(Icons.savings, size: 18),
                                    label: Text('Save $_lostAmount bob'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], padding: EdgeInsets.symmetric(vertical: 12)),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _withdrawSavings,
                                    child: Text('Withdraw', style: TextStyle(color: Colors.blue[700])),
                                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue[700]), padding: EdgeInsets.symmetric(vertical: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (_history.isNotEmpty)...[
              SizedBox(height: 24),
              Text('Recent Calculations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.history, color: Color(0xFF00B140)),
                      title: Text('KSh ${item['input']} → KSh ${item['result']}', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text('Lost ${item['lost']} bob', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500)),
                      onTap: () {
                        _controller.text = item['input'].toString();
                        _calculate();
                      },
                    ),
                  );
                },
              ),
            ],
            SizedBox(height: 80),
            if (_isBannerReady && _bannerAd!= null) Container(height: 50, child: AdWidget(ad: _bannerAd!)),
          ],
        ),
      ),
    );
  }
}
