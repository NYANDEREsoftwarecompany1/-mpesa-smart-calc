import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(MpesaCalcApp());
}

class MpesaCalcApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M-PESA Smart Calc KE',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00A651)),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF00A651),
        colorScheme: ColorScheme.dark(primary: Color(0xFF00A651)),
        scaffoldBackgroundColor: Color(0xFF121212),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  int? calculatedFee;
  int? totalAmount;
  String transactionType = 'TUMA';
  List<Map<String, dynamic>> history = [];
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  late TabController _tabController;

  // REPLACE WITH YOUR REAL AD IDS BEFORE PUBLISHING
  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // TEST
  final String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // TEST
  
  // YOUR PRIVACY POLICY URL - UPDATE AFTER GITHUB PAGES IS LIVE
  final String privacyPolicyUrl = 'https://nyanderesoftwarecompany.github.io/-mpesa-smart-calc/privacy_policy.html';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBannerAd();
    _loadInterstitialAd();
    _loadHistory();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, err) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) => _interstitialAd = null,
      ),
    );
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('calc_history');
    if (historyString!= null) {
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

  // 2026 M-PESA FEES - OFFICIAL SAFARICOM
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

  void calculateFees() {
    int amount = int.tryParse(_amountController.text)?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Weka kiasi sahihi')),
      );
      return;
    }

    int fee = transactionType == 'TUMA'? getSendFee(amount) : getWithdrawFee(amount);
    
    if (fee == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kiasi si sahihi. Minimum ni KSh 50')),
      );
      return;
    }

    setState(() {
      calculatedFee = fee;
      totalAmount = transactionType == 'TUMA'? amount + fee : amount - fee;
    });
    
    _saveToHistory(amount, fee, transactionType);
  }

  // USSD HANDOFF TO *334#
  Future<void> dialMpesaMenu() async {
    if (_interstitialAd!= null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
    
    final Uri ussd = Uri.parse('tel:*334%23');
    
    try {
      if (await canLaunchUrl(ussd)) {
        await launchUrl(ussd);
      } else {
        throw 'Could not launch';
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: '*334#'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('*334# copied. Fungua Phone app')),
      );
    }
  }

  Future<void> shareToWhatsApp() async {
    int amount = int.tryParse(_amountController.text)?? 0;
    int fee = calculatedFee?? 0;
    int total = transactionType == 'TUMA'? amount + fee : amount - fee;
    
    String message = '''M-PESA ${transactionType == 'TUMA'? 'Send' : 'Withdraw'}
Kiasi: KSh $amount
Ada: KSh $fee
${transactionType == 'TUMA'? 'Jumla: KSh $total' : 'Utapata: KSh $total'}

Piga *334# kutuma

Calculated via M-PESA Smart Calc KE''';

    await Share.share(message);
  }

  void copyDetails() {
    int amount = int.tryParse(_amountController.text)?? 0;
    int fee = calculatedFee?? 0;
    Clipboard.setData(ClipboardData(text: 'Kiasi: $amount, Ada: $fee'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied!')),
    );
  }

  void _openPrivacyPolicy() async {
    final Uri url = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('M-PESA Smart Calc KE'),
        backgroundColor: Color(0xFF00A651),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.privacy_tip_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Privacy & Terms'),
                  content: Text('We collect ZERO personal data.\n\nHistory saved only on your phone.\n\nNot affiliated with Safaricom.'),
                  actions: [
                    TextButton(
                      onPressed: _openPrivacyPolicy,
                      child: Text('Full Policy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'CALCULATE', icon: Icon(Icons.calculate)),
            Tab(text: 'HISTORIA', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: _isBannerAdReady
         ? Container(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : SizedBox(height: 50),
    );
  }

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'TUMA', label: Text('TUMA'), icon: Icon(Icons.send)),
              ButtonSegment(value: 'TOA', label: Text('TOA'), icon: Icon(Icons.money)),
            ],
            selected: {transactionType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                transactionType = newSelection.first;
                calculatedFee = null;
              });
            },
          ),
          
          SizedBox(height: 20),
          
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Weka Kiasi (KSh)',
              prefixText: 'KSh ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _amountController.clear();
                  setState(() => calculatedFee = null);
                },
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [100, 500, 1000, 2000, 5000, 10000].map((amt) {
              return ActionChip(
                label: Text('KSh $amt'),
                onPressed: () {
                  _amountController.text = amt.toString();
                  calculateFees();
                },
              );
            }).toList(),
          ),
          
          SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: calculateFees,
            child: Text('HESABU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A651),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          if (calculatedFee!= null)...[
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ada ya M-PESA:', style: TextStyle(fontSize: 16)),
                        Text('KSh $calculatedFee', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00A651))),
                      ],
                    ),
                    Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(transactionType == 'TUMA'? 'Jumla ya Kulipa:' : 'Utapata:', 
                          style: TextStyle(fontSize: 16)),
                        Text('KSh $totalAmount', 
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: dialMpesaMenu,
              icon: Icon(Icons.phone, size: 24),
              label: Text('DIAL *334# TO ${transactionType == 'TUMA'? 'SEND' : 'WITHDRAW'}', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A651),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: shareToWhatsApp,
                    icon: Icon(Icons.share, size: 20),
                    label: Text('WhatsApp'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: copyDetails,
                    icon: Icon(Icons.copy, size: 20),
                    label: Text('Copy'),
                  ),
                ),
              ],
            ),
          ],
          
          // YOUR SIGNATURE FOOTER - STANO ROTHSCHILD OBAKO
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF00A651).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Not affiliated with Safaricom PLC.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Calculator only. Fees updated: July 2026',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                Divider(height: 24, color: Color(0xFF00A651).withOpacity(0.3)),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 16, color: Color(0xFF00A651)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Crafted by Stano Rothschild Obako',
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A651),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF00A651).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐ 01 January 2003 - Forever Remembered ⭐',
                    style: TextStyle(
                      fontSize: 11, 
                      color: Color(0xFF00A651),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '© 2026 - Kisumu, Kenya 🇰🇪',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Hakuna Historia', style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Calculations zako zitaonekana hapa', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final date = DateTime.parse(item['date']);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item['type'] == 'TUMA'? Colors.blue : Colors.orange,
              child: Icon(item['type'] == 'TUMA'? Icons.send : Icons.money, color: Colors.white),
            ),
            title: Text('KSh ${item['amount']} - ${item['type']}', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Ada: KSh ${item['fee']} | ${date.day}/${date.month}/${date.year}'),
            trailing: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _amountController.text = item['amount'].toString();
                setState(() => transactionType = item['type']);
                _tabController.animateTo(0);
                calculateFees();
              },
            ),
          ),
        );
      },
    );
  }
}
