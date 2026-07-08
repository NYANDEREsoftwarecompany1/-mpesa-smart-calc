import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ad_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _showHome = true;
  final TextEditingController _amountController = TextEditingController();
  int? calculatedFee;
  int? totalAmount;
  String transactionType = 'TUMA';
  String userMode = 'CUSTOMER';
  List<Map<String, dynamic>> history = [];
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;

  final String privacyPolicyUrl = https://nyanderesoftwarecompany1.github.io/mpesa-smart-calc/privacy_policy.html

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
    _loadInterstitialAd();
    _loadHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInterstitialAd();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Welcome back! Calculate another fee?'),
            ],
          ),
          backgroundColor: Color(0xFF00A651),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'CALC',
            textColor: Colors.white,
            onPressed: () => setState(() => _showHome = false),
          ),
        ),
      );
    }
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(() {
      setState(() => _isBannerAdReady = true);
    });
  }

  void _loadInterstitialAd() {
    AdService.loadInterstitialAd((ad) {
      _interstitialAd = ad;
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('calc_history');
    if (historyString != null) {
      setState(() {
        history = List<Map<String, dynamic>>.from(json.decode(historyString));
      });
    }
  }

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
    if (amount <= 250000) return 108;
    return 0;
  }

  int getWithdrawFee(int amount) {
    if (amount < 50) return -1;
    if (amount <= 100) return 11;
    if (amount <= 500) return 29;
    if (amount <= 1000) return 29;
    if (amount <= 1500) return 29;
    if (amount <= 2500) return 29;
    if (amount <= 3500) return 52;
    if (amount <= 5000) return 69;
    if (amount <= 7500) return 87;
    if (amount <= 10000) return 115;
    if (amount <= 15000) return 167;
    if (amount <= 20000) return 185;
    if (amount <= 35000) return 197;
    if (amount <= 50000) return 278;
    if (amount <= 250000) return 309;
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

  void calculateFees() {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weka kiasi sahihi')),
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
        SnackBar(content: Text('Kiasi si sahihi. Minimum ni KSh 50')),
      );
      return;
    }
    
    setState(() {
      calculatedFee = fee;
      if (transactionType == 'TUMA' || transactionType == 'PAYBILL') {
        totalAmount = amount + fee;
      } else if (transactionType == 'TOA' || transactionType == 'POCHI') {
        totalAmount = amount - fee;
      } else {
        totalAmount = amount;
      }
    });
    _saveToHistory(amount, fee, transactionType);
  }

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
            content: Text('💚 Finish here, then come back to calculate more'),
            backgroundColor: Color(0xFF00A651),
            duration: Duration(seconds: 5),
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

  Future<void> _openPrivacyPolicy() async {
    final Uri url = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
              '⭐ 01 January 2003 - Forever Remembered ⭐',
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

  Widget _buildHomeChoice() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00A651).withOpacity(0.2), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Color(0xFF00A651).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 18, color: Color(0xFF00A651)),
                    SizedBox(width: 8),
                    Text(
                      'TRUSTED BY 50K+ KENYANS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00A651), letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text('M-PESA', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, shadows: [Shadow(color: Color(0xFF00A651).withOpacity(0.5), blurRadius: 20)])),
              SizedBox(height: 8),
              Text('Smart Calc KE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.grey.shade400, letterSpacing: 3)),
              SizedBox(height: 40),
              GestureDetector(
                onTap: dialMpesaMenu,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF00A651), Color(0xFF00C853)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Color(0xFF00A651).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.phone_android, size: 32, color: Colors.white)),
                        Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('INSTANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1))),
                      ]),
                      SizedBox(height: 20),
                      Text('M-PESA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      SizedBox(height: 8),
                      Text('Send • Withdraw • Pay Bills • Buy Airtime', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
                      SizedBox(height: 16),
                      Row(children: [Icon(Icons.bolt, size: 16, color: Colors.white), SizedBox(width: 6), Text('Direct to *334#', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600))]),
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
                  decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade800, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade900]), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.calculate_rounded, size: 32, color: Colors.white)),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFF00A651).withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.favorite, size: 12, color: Color(0xFF00A651)), SizedBox(width: 4), Text('WITH LOVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF00A651), letterSpacing: 0.5))])),
                          SizedBox(height: 6),
                          Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.3))), child: Text('SAVE MONEY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 1))),
                        ]),
                      ]),
                      SizedBox(height: 20),
                      Text('SMART CALC', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      SizedBox(height: 8),
                      Text('Check fees before you send', style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                      SizedBox(height: 16),
                      Row(children: [Icon(Icons.shield, size: 16, color: Colors.red), SizedBox(width: 6), Text('Avoid hidden charges', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600))]),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite, size: 14, color: Color(0xFF00A651)), SizedBox(width: 8), Text('Built with love in Kisumu', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500))])),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('M-PESA'),
        backgroundColor: Color(0xFF00A651),
        foregroundColor: Colors.white,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => setState(() => _showHome = true)),
        actions: [IconButton(icon: Icon(Icons.privacy_tip_outlined), onPressed: () { showDialog(context: context, builder: (context) => AlertDialog(title: Text('Privacy & Terms'), content: Text('We collect ZERO personal data.\n\nHistory saved only on your phone.\n\nNot affiliated with Safaricom.'), actions: [TextButton(onPressed: _openPrivacyPolicy, child: Text('Full Policy')), TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))]));})],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'CUSTOMER', label: Text('CUSTOMER'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'BUSINESS', label: Text('BIASHARA'), icon: Icon(Icons.store)),
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
                ? [
                    ButtonSegment(value: 'TUMA', label: Text('SEND'), icon: Icon(Icons.send)),
                    ButtonSegment(value: 'TOA', label: Text('WITHDRAW'), icon: Icon(Icons.money)),
                  ]
                : [
                    ButtonSegment(value: 'LIPA', label: Text('LIPA'), icon: Icon(Icons.shopping_cart)),
                    ButtonSegment(value: 'POCHI', label: Text('POCHI'), icon: Icon(Icons.account_balance_wallet)),
                    ButtonSegment(value: 'PAYBILL', label: Text('PAYBILL'), icon: Icon(Icons.receipt)),
                  ],
              selected: {transactionType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  transactionType = newSelection.first;
                  calculatedFee = null;
                });
              },
              style: SegmentedButton.styleFrom(selectedBackgroundColor: Color(0xFF00A651), selectedForegroundColor: Colors.white),
            ),
            SizedBox(height: 20),
            TextField(controller: _amountController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: 'Enter Amount', prefixText: 'KSh ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(icon: Icon(Icons.clear), onPressed: () { _amountController.clear(); setState(() => calculatedFee = null); }))),
            SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [100, 500, 1000, 2000, 5000, 10000].map((amt) { return ActionChip(label: Text('KSh $amt'), onPressed: () { _amountController.text = amt.toString(); calculateFees(); }); }).toList()),
            SizedBox(height: 20),
            ElevatedButton(onPressed: calculateFees, child: Text('CALCULATE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A651), foregroundColor: Colors.white, minimumSize: Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
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
                            transactionType == 'TUMA' ? 'Send Fee:' 
                            : transactionType == 'TOA' ? 'Withdraw Fee:' 
                            : transactionType == 'LIPA' ? 'Lipa Fee:' 
                            : transactionType == 'POCHI' ? 'Pochi Fee:' 
                            : 'Paybill Fee:', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                          ), 
                          Text(
                            'KSh $calculatedFee', 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00A651))
                          )
                        ]
                      ),
                      Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(
                            transactionType == 'TUMA' || transactionType == 'PAYBILL' ? 'Total to Send:' 
                            : transactionType == 'TOA' || transactionType == 'POCHI' ? 'You Receive:' 
                            : 'Customer Pays:', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                          ), 
                          Text(
                            'KSh $totalAmount', 
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                          )
                        ]
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                        decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), 
                        child: Text(
                          transactionType == 'TUMA' ? 'Send Fee: KSh $calculatedFee' 
                          : transactionType == 'TOA' ? 'Withdraw Fee: KSh $calculatedFee' 
                          : transactionType == 'LIPA' ? 'Lipa Fee: KSh $calculatedFee' 
                          : transactionType == 'POCHI' ? 'Pochi Fee: KSh $calculatedFee' 
                          : 'Paybill Fee: KSh $calculatedFee', 
                          style: TextStyle(fontSize: 12, color: Color(0xFF00A651), fontWeight: FontWeight.w600)
                        )
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), 
                        child: Text(
                          'Agent is right ✓', 
                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)
                        )
                      ),
                    ]
                  )
                )
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_interstitialAd != null) {
                    await _interstitialAd!.show();
                    _interstitialAd = null;
                    _loadInterstitialAd();
                  }
                  
                  String instructions = '';
                  if (transactionType == 'TUMA') {
                    instructions = 'After *334#: Select 1 → Send Money → Enter Number → KSh ${_amountController.text}';
                  } else if (transactionType == 'TOA') {
                    instructions = 'After *334#: Select 2 → Withdraw → Agent No → KSh ${_amountController.text}';
                  } else if (transactionType == 'LIPA') {
                    instructions = 'After *334#: Select 4 → Lipa na M-PESA → Buy Goods → Till No → KSh ${_amountController.text}';
                  } else if (transactionType == 'POCHI') {
                    instructions = 'After *334#: Select 4 → Pochi la Biashara → Withdraw → KSh ${_amountController.text}';
                  } else if (transactionType == 'PAYBILL') {
                    instructions = 'After *334#: Select 4 → Lipa na M-PESA → PayBill → Business No → KSh ${_amountController.text}';
                  }
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF00A651)),
                          SizedBox(width: 8),
                          Text('M-PESA Steps'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF00A651).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Amount: KSh ${_amountController.text}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Fee: KSh $calculatedFee', style: TextStyle(color: Color(0xFF00A651), fontWeight: FontWeight.bold)),
                                Text('Total: KSh $totalAmount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text('Follow these steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(instructions, style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final Uri ussd = Uri.parse('tel:*334%23');
                            try {
                              if (await canLaunchUrl(ussd)) {
                                await launchUrl(ussd);
                              }
                            } catch (e) {
                              await Clipboard.setData(ClipboardData(text: '*334#'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('*334# copied. Fungua Phone app')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A651)),
                          child: Text('OPEN *334#'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.phone_android, size: 22),
                label: Text(
                  transactionType == 'TUMA' ? 'SEND NOW VIA M-PESA' 
                  : transactionType == 'TOA' ? 'WITHDRAW NOW VIA M-PESA'
                  : transactionType == 'LIPA' ? 'PAY TILL VIA M-PESA'
                  : transactionType == 'POCHI' ? 'POCHI VIA M-PESA'
                  : 'PAYBILL VIA M-PESA', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00A651), 
                  foregroundColor: Colors.white, 
                  minimumSize: Size(double.infinity, 58), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), 
                  elevation: 6, 
                  shadowColor: Color(0xFF00A651).withOpacity(0.5)
                )
              ),
            ],
            SizedBox(height: 30),
            Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade800]), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFF00A651).withOpacity(0.3), width: 1)), child: Column(children: [Text('Not affiliated with Safaricom PLC.', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center), SizedBox(height: 4), Text('Fees updated: July 2026', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center), Divider(height: 24, color: Color(0xFF00A651).withOpacity(0.3)), Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, size: 16, color: Color(0xFF00A651)), SizedBox(width: 6), Flexible(child: Text('Crafted by Stano Rothschild Obako', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A651), letterSpacing: 0.5), textAlign: TextAlign.center))]), SizedBox(height: 6), Text('© 2026 - Kisumu, Kenya 🇰🇪', style: TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center)])),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
