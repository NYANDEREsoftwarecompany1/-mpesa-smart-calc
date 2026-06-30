import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _amountController = TextEditingController();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int? _resultAmount;
  int? _lostAmount;
  bool _showResult = false;
  int _calculateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    // Delay = "content before ads" rule. Missing = AdMob holds money
    await Future.delayed(const Duration(seconds: 1));
    _bannerAd = await AdService.createBannerAd(context);
    await _bannerAd!.load();
    if (mounted) {
      setState(() {
        _isAdLoaded = true;
      });
    }
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_amountController.text.isEmpty) return;

    int input = int.tryParse(_amountController.text)?? 0;
    if (input <= 0) return;

    int rounded = ((input + 9) ~/ 10) * 10;
    int lost = rounded - input;

    setState(() {
      _resultAmount = rounded;
      _lostAmount = lost;
      _showResult = true;
      _calculateCount++;
    });

    // Show interstitial only every 3rd calc = prevents "intrusive ads" ban
    if (_calculateCount % 3 == 0) {
      AdService.showInterstitialIfReady();
    }
  }

  void _copyResult() {
    if (_resultAmount!= null) {
      Clipboard.setData(ClipboardData(text: 'Send ${_resultAmount!}'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: Send $_resultAmount'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'M-PESA Smart Calc KE',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00B140),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Enter Amount',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'KSh ',
                      prefixStyle: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00B140)),
                      hintText: '237',
                      hintStyle: TextStyle(fontSize: 40, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF00B140), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF00B140), width: 3),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _calculate(),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B140),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: const Text(
                      'CALCULATE',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedOpacity(
                    opacity: _showResult? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _showResult
                       ? Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00B140), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text('Send:', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text(
                                  'KSh $_resultAmount',
                                  style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Color(0xFF00B140)),
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'You lose: $_lostAmount bob',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red[700]),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('Agent is right ✅', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _copyResult,
                                  icon: const Icon(Icons.copy, color: Colors.white),
                                  label: const Text('COPY TO M-PESA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B140),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(height: 200),
                  ),
                ],
              ),
            ),
          ),
          if (_isAdLoaded && _bannerAd!= null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            const SizedBox(height: 50),
        ],
      ),
    );
  }
}