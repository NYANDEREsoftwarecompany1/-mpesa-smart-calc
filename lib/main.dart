import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF00A651),
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

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _amountController = TextEditingController();
  int? calculatedFee;
  int? totalAmount;
  String transactionType = 'TUMA'; // TUMA or TOA
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;

  // REPLACE WITH YOUR REAL AD IDS BEFORE PUBLISHING
  final String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // TEST ID
  final String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // TEST ID

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
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

  // 2026 M-PESA FEES - OFFICIAL SAFARICOM
  int getSendFee(int amount) {
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
    return 108;
  }

  int getWithdrawFee(int amount) {
    if (amount < 50) return -1; // Invalid
    if (amount <= 100) return 11;
    if (amount <= 2500) return 29;
    if (amount <= 3500) return 52;
    if (amount <= 5000) return 69;
    if (amount <= 7500) return 87;
    if (amount <= 10000) return 115;
    if (amount <= 15000) return 167;
    if (amount <= 20000) return 185;
    if (amount <= 35000) return 197;
    if (amount <= 50000) return 278;
    return 309;
  }

  void calculateFees() {
    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    int fee = transactionType == 'TUMA' ? getSendFee(amount) : getWithdrawFee(amount);
    
    if (fee == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum withdraw ni KSh 50')),
      );
      return;
    }

    setState(() {
      calculatedFee = fee;
      totalAmount = transactionType == 'TUMA' ? amount + fee : amount - fee;
    });
  }

  // USSD HANDOFF TO *334#
  Future<void> dialMpesaMenu() async {
    // Show ad first for revenue
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
    
    // Open phone dialer with *334#
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
        SnackBar(content: Text('*334# copied. Open Phone app and paste to dial')),
      );
    }
  }

  // SHARE TO WHATSAPP
  Future<void> shareToWhatsApp() async {
    int amount = int.tryParse(_amountController.text) ?? 0;
    int fee = calculatedFee ?? 0;
    int total = transactionType == 'TUMA' ? amount + fee : amount - fee;
    
    String message = '''M-PESA ${transactionType == 'TUMA' ? 'Send' : 'Withdraw'}
Amount: KSh $amount
Fee: KSh $fee
${transactionType == 'TUMA' ? 'Total: KSh $total' : 'You Get: KSh $total'}

Dial *334# to proceed

Calculated via M-PESA Smart Calc KE''';

    await Share.share(message);
  }

  void copyDetails() {
    int amount = int.tryParse(_amountController.text) ?? 0;
    int fee = calculatedFee ?? 0;
    String text = 'Amount: $amount, Fee: $fee';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied! $text')),
    );
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
      appBar: AppBar(
        title: Text('M-PESA Smart Calc KE'),
        backgroundColor: Color(0xFF00A651),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transaction Type Toggle
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
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Weka Kiasi (KSh)',
                prefixText: 'KSh ',
                border: OutlineInputBorder(),
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
            
            // Quick Amount Buttons
            Wrap(
              spacing: 8,
              children: [100, 500, 1000, 2000, 5000, 10000].map((amt) {
                return ActionChip(
                  label: Text('$amt'),
                  onPressed: () {
                    _amountController.text = amt.toString();
                    calculateFees();
                  },
                );
              }).toList(),
            ),
            
            SizedBox(height: 20),
            
            // Calculate Button
            ElevatedButton(
              onPressed: calculateFees,
              child: Text('HESABU', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A651),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Results
            if (calculatedFee != null) ...[
              Card(
                color: Color(0xFF00A651).withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ada (Fee):', style: TextStyle(fontSize: 16)),
                          Text('KSh $calculatedFee', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A651))),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(transactionType == 'TUMA' ? 'Jumla (Total):' : 'Utapata (You Get):', 
                            style: TextStyle(fontSize: 16)),
                          Text('KSh $totalAmount', 
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // DIAL *334# BUTTON - MAIN ACTION
              ElevatedButton.icon(
                onPressed: dialMpesaMenu,
                icon: Icon(Icons.phone),
                label: Text('DIAL *334# TO ${transactionType == 'TUMA' ? 'SEND' : 'WITHDRAW'}', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 55),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Share Button
              OutlinedButton.icon(
                onPressed: shareToWhatsApp,
                icon: Icon(Icons.share),
                label: Text('Share to WhatsApp'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
              
              SizedBox(height: 10),
              
              // Copy Button
              TextButton.icon(
                onPressed: copyDetails,
                icon: Icon(Icons.copy, size: 18),
                label: Text('Copy Details'),
              ),
            ],
            
            SizedBox(height: 30),
            
            // Disclaimer
            Text(
              'Not affiliated with Safaricom M-PESA.\nOpens official *334# menu. We don\'t process money.\nFees updated: July 2026',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 80), // Space for banner
          ],
        ),
      ),
      
      // Banner Ad
      bottomNavigationBar: _isBannerAdReady
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : SizedBox(height: 50),
    );
  }
}
