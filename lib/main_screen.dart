import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  // ========== VIP CONFIG - EDIT HAPA TU ==========
  final String privacyPolicyUrl = 'https://nyanderesoftwarecompany1.github.io/mpesa-smart-calc/privacy_policy.html';
  // ==============================================
  
  bool _showHome = true;
  String userMode = 'CUSTOMER';
  String transactionType = 'TUMA';
  final _amountController = TextEditingController();
  int? calculatedFee;
  int? totalAmount;
  
  // ADMOB VARIABLES
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;
  
  // HISTORY
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
    _loadHistory();
  }

  // ADMOB - BANNER
  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(() {
      setState(() => _isBannerAdReady = true);
    });
  }

  // ADMOB - INTERSTITIAL
  void _loadInterstitialAd() {
    AdService.loadInterstitialAd((ad) {
      _interstitialAd = ad;
    });
  }

  // HISTORY - LOAD
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('calc_history');
    if (historyString != null) {
      setState(() {
        history = List<Map<String, dynamic>>.from(json.decode(historyString));
      });
    }
  }

  // HISTORY - SAVE
  Future<void> _saveToHistory(int amount, int fee, String type) async {
    final prefs = await SharedPreferences.getInstance();
    history.insert(0, {
      'amount': amount,
      'fee': fee,
      'type': type,
      'date': DateTime.now().toIso8601String(),
    });
    if (history.length > 50) history.removeLast();
    await prefs.setString('calc_history', json.encode(history));
  }

  // FEES LOGIC - SAFARICOM JULY 2026
  int getSendFee(int amount) {
    if (amount <= 0) return 0;
    if (amount <= 100) return 0;
    if (amount <= 500) return 7;
    if (amount <= 1000) return 13;
    if (amount <= 1500) return 23;
    if (amount <= 2500) return 33;
    if (amount <= 3500) return 53;
    if (amount <= 5000) return 57;
    if (amount <= 7500) return 78;
    if (amount <= 10000) return 90;
    if (amount <= 15000) return 100;
    if (amount <= 20000) return 105;
    if (amount <= 35000) return 108;
    if (amount <= 50000) return 108;
    if (amount <= 250000) return 108;
    return -1;
  }

  int getWithdrawFee(int amount) {
    if (amount < 50) return -1;
    if (amount <= 100) return 0;
    if (amount <= 500) return 27;
    if (amount <= 1000) return 28;
    if (amount <= 1500) return 28;
    if (amount <= 2500) return 28;
    if (amount <= 3500) return 50;
    if (amount <= 5000) return 67;
    if (amount <= 7500) return 84;
    if (amount <= 10000) return 112;
    if (amount <= 15000) return 162;
    if (amount <= 20000) return 180;
    if (amount <= 35000) return 191;
    if (amount <= 50000) return 270;
    if (amount <= 250000) return 300;
    return -1;
  }

  int getLipaFee(int amount) {
    if (amount <= 3500) return 0;
    return 10;
  }

  int getPochiFee(int amount) {
    if (amount < 50) return -1;
    if (amount <= 3500) return 0;
    if (amount <= 7500) return 15;
    return 25;
  }

  int getPaybillFee(int amount) {
    if (amount <= 1000) return 0;
    if (amount <= 7500) return 10;
    return 20;
  }

  // CALCULATE FEES
  void calculateFees() {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weka kiasi sahihi'), backgroundColor: Colors.red),
      );
      return;
    }

    int fee = 0;
    if (transactionType == 'TUMA') fee = getSendFee(amount);
    else if (transactionType == 'TOA') fee = getWithdrawFee(amount);
    else if (transactionType == 'LIPA') fee = getLipaFee(amount);
    else if (transactionType == 'POCHI') fee = getPochiFee(amount);
    else if (transactionType == 'PAYBILL') fee = getPaybillFee(amount);

    if (fee == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kiasi si sahihi. Minimum: KSh 50'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      calculatedFee = fee;
      if (transactionType == 'TUMA' || transactionType == 'LIPA' || transactionType == 'POCHI' || transactionType == 'PAYBILL') {
        totalAmount = amount + fee;
      } else if (transactionType == 'TOA') {
        totalAmount = amount - fee;
      } else {
        totalAmount = amount;
      }
    });
    _saveToHistory(amount, fee, transactionType);
  }

  // CALL M-PESA *334#
  Future<void> dialMpesaMenu() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
    
    final Uri ussd = Uri.parse('tel:*334%23');
    try {
      if (await canLaunchUrl(ussd)) {
        await launchUrl(ussd);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💚 Finish here, then come back to calculate'),
            backgroundColor: Color(0xFF00A651),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'CALC',
              textColor: Colors.white,
              onPressed: () => setState(() => _showHome = false),
            ),
          ),
        );
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: '*334#'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('*334# copied. Fungua Phone app')),
      );
    }
  }

  // PRIVACY POLICY - VIP FUNCTION
  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse(privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Privacy Policy'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: _showHome ? _buildHomeChoice() : _buildCalculatorScreen(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6),
            color: Color(0xFF00A651).withOpacity(0.15),
            child: Text(
              '★ 01 January 2003 - Forever Remembered',
              style: TextStyle(
                color: Color(0xFF00A651),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_isBannerAdReady)
            Container(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            SizedBox(height: 50),
        ],
      ),
    );
  }

  // HOME SCREEN
  Widget _buildHomeChoice() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00A651).withOpacity(0.2), Color(0xFF00A651).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF00A651).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 18, color: Color(0xFF00A651)),
                    SizedBox(width: 8),
                    Text(
                      'TRUSTED BY 50K+ KENYANS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00A651)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text('M-PESA', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              SizedBox(height: 8),
              Text('Smart Calc KE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF00A651))),
              SizedBox(height: 40),
              GestureDetector(
                onTap: dialMpesaMenu,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF00A651), Color(0xFF008A44)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Color(0xFF00A651).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.phone, color: Colors.white, size: 28)),
                        Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                      ]),
                      SizedBox(height: 20),
                      Text('M-PESA', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      SizedBox(height: 8),
                      Text('Send • Withdraw • Pay Bills', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                      SizedBox(height: 16),
                      Row(children: [Icon(Icons.bolt, color: Colors.white, size: 18), SizedBox(width: 6), Text('Instant Access', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (_interstitialAd != null) {
                    await _interstitialAd!.show();
                    _interstitialAd = null;
                    _loadInterstitialAd();
                  }
                  setState(() => _showHome = false);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(color: Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Color(0xFF3A3A3A), width: 1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.calculate, color: Color(0xFF00A651), size: 28)),
                        Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text('SMART', style: TextStyle(color: Color(0xFF00A651), fontSize: 11, fontWeight: FontWeight.w700))),
                      ]),
                      SizedBox(height: 20),
                      Text('SMART CALC', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      SizedBox(height: 8),
                      Text('Check fees before you send', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      SizedBox(height: 16),
                      Row(children: [Icon(Icons.shield_outlined, color: Color(0xFF00A651), size: 18), SizedBox(width: 6), Text('Avoid Surprises', style: TextStyle(color: Color(0xFF00A651), fontSize: 13, fontWeight: FontWeight.w600))]),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00A651).withOpacity(0.2))),
                child: Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFF00A651), size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Check charges before sending. Save money.', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // CALCULATOR SCREEN
  Widget _buildCalculatorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('M-PESA'),
        backgroundColor: Color(0xFF00A651),
        foregroundColor: Colors.white,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => setState(() => _showHome = true)),
        actions: [IconButton(icon: Icon(Icons.privacy_tip_outlined), onPressed: _openPrivacyPolicy, tooltip: 'Privacy Policy')],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'CUSTOMER', label: Text('Customer')),
                ButtonSegment(value: 'BUSINESS', label: Text('Business')),
              ],
              selected: {userMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  userMode = newSelection.first;
                  transactionType = userMode == 'CUSTOMER' ? 'TUMA' : 'LIPA';
                  calculatedFee = null;
                });
              },
            ),
            SizedBox(height: 12),
            SegmentedButton<String>(
              segments: userMode == 'CUSTOMER'
                  ? [ButtonSegment(value: 'TUMA', label: Text('Tuma')), ButtonSegment(value: 'TOA', label: Text('Toa'))]
                  : [ButtonSegment(value: 'LIPA', label: Text('Lipa')), ButtonSegment(value: 'POCHI', label: Text('Pochi')), ButtonSegment(value: 'PAYBILL', label: Text('Paybill'))],
              selected: {transactionType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  transactionType = newSelection.first;
                  calculatedFee = null;
                });
              },
              style: SegmentedButton.styleFrom(selectedBackgroundColor: Color(0xFF00A651)),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weka Kiasi (KSh)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.money),
                filled: true,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: calculateFees,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Hesabu Ada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (calculatedFee != null) ...[
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transactionType == 'TUMA' ? 'Tuma Fee:' : transactionType == 'TOA' ? 'Toa Fee:' : transactionType == 'LIPA' ? 'Lipa Fee:' : transactionType == 'POCHI' ? 'Pochi Fee:' : 'Paybill Fee:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'KSh $calculatedFee',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A651)),
                          )
                        ],
                      ),
                      Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transactionType == 'TUMA' || transactionType == 'LIPA' || transactionType == 'POCHI' || transactionType == 'PAYBILL' ? 'Customer Pays:' : 'You Receive:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'KSh $totalAmount',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF00A651).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💚 Hakikisha umecheck ada kabla ya kutuma',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00A651), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 30),
            // VIP SETTINGS SECTION
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.privacy_tip_outlined, color: Color(0xFF00A651)),
                    title: Text('Privacy Policy'),
                    subtitle: Text('How we handle your data'),
                    trailing: Icon(Icons.open_in_new),
                    onTap: _openPrivacyPolicy,
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF00A651)),
                    title: Text('About App'),
                    subtitle: Text('M-PESA Smart Calc KE v1.0'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'M-PESA Smart Calc KE',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(Icons.calculate, color: Color(0xFF00A651)),
                        children: [Text('Calculate M-PESA charges instantly. Save money.')],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
