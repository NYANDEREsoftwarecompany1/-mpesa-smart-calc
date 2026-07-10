import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String privacyPolicyUrl = 'https://nyanderesoftwarecompany1.github.io/mpesa-smart-calc/privacy_policy.html';
  
  bool _showHome = true;
  bool isEnglish = false; // false = Swahili, true = English
  String userMode = 'Customer';
  String transactionType = 'Tuma';
  final _amountController = TextEditingController();
  int? calculatedFee;
  int? totalAmount;
  
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;

  // TRANSLATIONS
  String t(String sw, String en) => isEnglish ? en : sw;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd(() => setState(() => _isBannerAdReady = true));
  }

  void _loadInterstitialAd() {
    AdService.loadInterstitialAd((ad) => _interstitialAd = ad);
  }

  // 2026 CORRECT FEES - FIXED BY YOU
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
    if (amount <= 35000) return 108;
    if (amount <= 50000) return 108;
    if (amount <= 250000) return 108;
    return -1;
  }

  // FIXED: 1-500 = 29 (NOT 27)
  int getWithdrawFee(int amount) {
    if (amount < 1) return -1;
    if (amount <= 100) return 0;
    if (amount <= 500) return 29; // FIXED - WAS 27
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

  int getBusinessFee(int amount, String type) {
    if (type == 'Lipa') return 0; // Till is free
    if (type == 'Pochi') return 0; // Pochi free
    if (type == 'Paybill') {
      if (amount <= 100) return 0;
      if (amount <= 500) return 7;
      if (amount <= 1000) return 13;
      if (amount <= 1500) return 23;
      if (amount <= 2500) return 33;
      if (amount <= 3500) return 53;
      return 57;
    }
    return getSendFee(amount);
  }

  void calculateFees() {
    int amount = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Weka kiasi sahihi', 'Enter valid amount'))));
      return;
    }
    int fee;
    if (userMode == 'Customer') {
      fee = transactionType == 'Tuma' ? getSendFee(amount) : getWithdrawFee(amount);
    } else {
      fee = getBusinessFee(amount, transactionType);
    }
    if (fee == -1) return;
    setState(() {
      calculatedFee = fee;
      totalAmount = transactionType == 'Toa' ? amount - fee : amount + fee;
      if (transactionType == 'Toa' && transactionType != 'Tuma') {
        totalAmount = amount - fee;
      } else if (transactionType == 'Tuma' || transactionType == 'Paybill') {
        totalAmount = amount + fee;
      } else {
        totalAmount = amount;
      }
    });
  }

  // BUTTON INABADILIKA KWA KILA TYPE - INAPELEKA *334#
  String getActionButtonText() {
    switch (transactionType) {
      case 'Tuma': return t('TUMA SASA VIA M-PESA', 'SEND NOW VIA M-PESA');
      case 'Toa': return t('TOA SASA VIA M-PESA', 'WITHDRAW NOW');
      case 'Lipa': return t('LIPA TILL SASA', 'PAY TILL NOW');
      case 'Pochi': return t('TUMA POCHI LA BIASHARA', 'SEND TO POCHI');
      case 'Paybill': return t('LIPA PAYBILL SASA', 'PAY PAYBILL NOW');
      default: return t('TUMA SASA', 'SEND NOW');
    }
  }

  IconData getActionIcon() {
    switch (transactionType) {
      case 'Tuma': return Icons.send_rounded;
      case 'Toa': return Icons.money_off_rounded;
      case 'Lipa': return Icons.storefront_rounded;
      case 'Pochi': return Icons.account_balance_wallet_rounded;
      case 'Paybill': return Icons.receipt_long_rounded;
      default: return Icons.phone;
    }
  }

  Future<void> dialMpesaAction() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
    final Uri ussd = Uri.parse('tel:*334%23');
    try {
      if (await canLaunchUrl(ussd)) {
        await launchUrl(ussd);
      } else {
        await Clipboard.setData(ClipboardData(text: '*334#'));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('*334# copied', '*334# copied'))));
      }
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: '*334#'));
    }
  }

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication);
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
      body: _showHome ? _buildHome() : _buildCalc(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Color(0xFF1A1A1A),
            child: Row(
              children: [
                Icon(Icons.favorite, color: Color(0xFF00A651), size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('Hakikisha umecheck ada kabla ya kutuma 💚', 'Always check fees before sending 💚'),
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 5),
            color: Color(0xFF00A651).withOpacity(0.15),
            child: Text('★ 01 January 2003 - Forever Remembered ★',
              style: TextStyle(color: Color(0xFF00A651), fontSize: 10, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          ),
          if (_isBannerAdReady)
            Container(height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!)),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => setState(() => isEnglish = !isEnglish),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF00A651).withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.language, size: 16, color: Color(0xFF00A651)),
                    SizedBox(width: 6),
                    Text(isEnglish ? 'EN' : 'SW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('TRUSTED BY 50K+ KENYANS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00A651))),
            ),
            SizedBox(height: 20),
            Text('M-PESA', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            Text('Smart Calc KE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF00A651))),
            SizedBox(height: 30),
            GestureDetector(
              onTap: dialMpesaAction,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF00A651), Color(0xFF008A44)]), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 28),
                    Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)), child: Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ]),
                  SizedBox(height: 16),
                  Text('M-PESA', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text(t('Tuma • Toa • Lipa Bili', 'Send • Withdraw • Pay Bills'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                  SizedBox(height: 12),
                  Row(children: [Icon(Icons.bolt, color: Colors.white, size: 16), SizedBox(width: 4), Text(t('Bonyeza kupiga *334#', 'Tap to dial *334#'), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
                ]),
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _showHome = false),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Color(0xFF232323), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(0xFF333333))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.calculate_rounded, color: Color(0xFF00A651), size: 24)),
                    Text('SMART', style: TextStyle(color: Color(0xFF00A651), fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 16),
                  Text('SMART CALC', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text(t('Angalia ada kabla ya kutuma', 'Check fees before you send'), style: TextStyle(color: Colors.white60, fontSize: 13)),
                ]),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalc() {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('M-PESA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF00A651),
        foregroundColor: Colors.white,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _showHome = true)),
        actions: [
          // LANGUAGE BUTTON - BADALA YA ❄️
          GestureDetector(
            onTap: () => setState(() => isEnglish = !isEnglish),
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.language, size: 18, color: Colors.white),
                SizedBox(width: 4),
                Text(isEnglish ? 'SW' : 'EN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ),
          ),
          IconButton(icon: Icon(Icons.shield_outlined), onPressed: _openPrivacyPolicy, tooltip: 'Privacy Policy'),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Customer', label: Text(t('Customer', 'Customer')), icon: Icon(Icons.person, size: 16)),
                ButtonSegment(value: 'Business', label: Text(t('Biashara', 'Business')), icon: Icon(Icons.store, size: 16)),
              ],
              selected: {userMode},
              onSelectionChanged: (s) => setState(() {
                userMode = s.first;
                transactionType = userMode == 'Customer' ? 'Tuma' : 'Lipa';
                calculatedFee = null;
              }),
            ),
            SizedBox(height: 12),
            SegmentedButton<String>(
              segments: userMode == 'Customer'
                  ? [
                      ButtonSegment(value: 'Tuma', label: Text(t('Tuma', 'Send')), icon: Icon(Icons.send, size: 16)),
                      ButtonSegment(value: 'Toa', label: Text(t('Toa', 'Withdraw')), icon: Icon(Icons.money_off, size: 16)),
                    ]
                  : [
                      ButtonSegment(value: 'Lipa', label: Text('LIPA'), icon: Icon(Icons.storefront, size: 14)),
                      ButtonSegment(value: 'Pochi', label: Text('POCHI'), icon: Icon(Icons.wallet, size: 14)),
                      ButtonSegment(value: 'Paybill', label: Text('PAYBILL'), icon: Icon(Icons.receipt, size: 14)),
                    ],
              selected: {transactionType},
              onSelectionChanged: (s) => setState(() {
                transactionType = s.first;
                calculatedFee = null;
                totalAmount = null;
              }),
              style: SegmentedButton.styleFrom(selectedBackgroundColor: Color(0xFF00A651), selectedForegroundColor: Colors.white),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: t('Weka Kiasi (KSh)', 'Enter Amount (KSh)'),
                prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFF00A651)),
                suffixIcon: _amountController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear), onPressed: () => setState(() { _amountController.clear(); calculatedFee = null; })) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Color(0xFF00A651), width: 2)),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
              ),
              onChanged: (v) => setState(() {}),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [100, 500, 1000, 2000, 5000, 10000].map((amt) => ActionChip(
                label: Text('KSh $amt'),
                onPressed: () { _amountController.text = amt.toString(); calculateFees(); },
                backgroundColor: Color(0xFF2A2A2A),
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                side: BorderSide(color: Color(0xFF3A3A3A)),
              )).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: calculateFees,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A651), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: Text(t('Hesabu Ada', 'Calculate Fee'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (calculatedFee != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF2A2A2A))),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('$transactionType ${t('Ada', 'Fee')}:', style: TextStyle(fontSize: 15, color: Colors.white70)),
                    Text('KSh $calculatedFee', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: calculatedFee == 0 ? Colors.green : Color(0xFF00A651))),
                  ]),
                  Divider(height: 28, color: Color(0xFF333333)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(transactionType == 'Toa' ? t('Utapokea', 'You Receive') : t('Mteja Atalipa', 'Customer Pays'), style: TextStyle(fontSize: 15, color: Colors.white70)),
                    Text('KSh $totalAmount', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                  SizedBox(height: 14),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Color(0xFF00A651).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.favorite, size: 14, color: Color(0xFF00A651)),
                      SizedBox(width: 6),
                      Text(t('Hakikisha umecheck ada kabla ya kutuma', 'Fee verified ✓'), style: TextStyle(color: Color(0xFF00A651), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
              SizedBox(height: 16),
              // BUTTON INAYOBADILIKA - HII NDIO ULIOMBA
              ElevatedButton.icon(
                onPressed: dialMpesaAction,
                icon: Icon(getActionIcon(), size: 22),
                label: Text(getActionButtonText(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A651), foregroundColor: Colors.white, minimumSize: Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 2),
              ),
            ],
            SizedBox(height: 24),
            Card(
              color: Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                ListTile(leading: Icon(Icons.privacy_tip_outlined, color: Color(0xFF00A651)), title: Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(t('Jinsi tunavyolinda data yako', 'How we handle your data'), style: TextStyle(fontSize: 12, color: Colors.white54)), trailing: Icon(Icons.open_in_new, size: 18, color: Colors.white54), onTap: _openPrivacyPolicy),
                Divider(height: 1, color: Color(0xFF2A2A2A)),
                ListTile(leading: Icon(Icons.info_outline_rounded, color: Color(0xFF00A651)), title: Text(t('Kuhusu App', 'About App'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text('M-PESA Smart Calc KE v1.0', style: TextStyle(fontSize: 12, color: Colors.white54)), onTap: () => showAboutDialog(context: context, applicationName: 'M-PESA Smart Calc KE', applicationVersion: '1.0.0', children: [Text(t('Piga hesabu ada za M-PESA papo hapo.', 'Calculate M-PESA charges instantly.'))])),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
