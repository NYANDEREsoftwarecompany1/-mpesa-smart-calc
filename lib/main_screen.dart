import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _adError = ''; // ← SHOW ERROR ON SCREEN
  int? _resultAmount;
  int? _lostAmount;
  bool _showResult = false;
  int _calculateCount = 0;
  bool _isDarkMode = false;
  bool _isWithdrawMode = false;
  bool _isSwahili = false;
  List<String> _history = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    AdService.loadInterstitialAd();
    _loadBannerAd();
    _loadHistory();
  }

  Future<void> _loadBannerAd() async {
    await Future.delayed(const Duration(seconds: 1));
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ BANNER LOADED');
          if (mounted) setState(() {
            _isAdLoaded = true;
            _adError = '';
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ BANNER FAILED: ${error.message}');
          if (mounted) setState(() {
            _adError = 'Ad Error: ${error.message}'; // ← SHOW ON SCREEN
          });
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    await _bannerAd!.load();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('history')?? [];
    });
  }

  Future<void> _saveToHistory(String entry) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, entry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await prefs.setStringList('history', _history);
  }

  int _getWithdrawFee(int amount) {
    if (amount <= 100) return 10;
    if (amount <= 500) return 27;
    if (amount <= 1000) return 28;
    if (amount <= 1500) return 28;
    if (amount <= 2500) return 28;
    if (amount <= 3500) return 50;
    if (amount <= 5000) return 50;
    if (amount <= 7500) return 75;
    if (amount <= 10000) return 75;
    if (amount <= 15000) return 95;
    if (amount <= 20000) return 95;
    if (amount <= 35000) return 100;
    if (amount <= 50000) return 100;
    return 110;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (_amountController.text.isEmpty) return;

    int input = int.tryParse(_amountController.text)?? 0;
    if (input <= 0) return;

    int rounded, lost;

    if (_isWithdrawMode) {
      int fee = _getWithdrawFee(input);
      rounded = input + fee + 20;
      lost = fee + 20;
    } else {
      rounded = ((input + 9) ~/ 10) * 10;
      lost = rounded - input;
    }

    setState(() {
      _resultAmount = rounded;
      _lostAmount = lost;
      _showResult = true;
      _calculateCount++;
    });

    String mode = _isWithdrawMode? 'Toa' : 'Tuma';
    _saveToHistory('$mode $input → KSh $rounded');

    if (_calculateCount % 3 == 0) {
      AdService.showInterstitialIfReady();
    }
  }

  void _copyResult() {
    if (_resultAmount!= null) {
      final text = _isWithdrawMode? 'Withdraw KSh $_resultAmount' : 'Send KSh $_resultAmount';
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied: $text'), duration: const Duration(seconds: 2), backgroundColor: const Color(0xFF00B140)),
      );
    }
  }

  void _shareResult() {
    if (_resultAmount!= null) {
      final text = _isWithdrawMode
       ? 'Kutoa KSh ${_amountController.text}, mwambie agent KSh $_resultAmount\nAda: $_lostAmount bob\n\n_Calculated by M-PESA Smart Calc KE_'
        : 'Kutuma KSh ${_amountController.text}, tumia KSh $_resultAmount\nUnapoteza: $_lostAmount bob\n\n_Calculated by M-PESA Smart Calc KE_';
      Share.share(text);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildCalculator(bool isDark) {
    final bgColor = isDark? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark? Colors.white : Colors.black;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWithdrawMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color:!_isWithdrawMode? const Color(0xFF00B140) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(_isSwahili? 'TUMA' : 'SEND', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color:!_isWithdrawMode? Colors.white : textColor)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isWithdrawMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _isWithdrawMode? const Color(0xFF00B140) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(_isSwahili? 'TOA' : 'WITHDRAW', textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isWithdrawMode? Colors.white : textColor)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(_isSwahili? 'Weka Kiasi' : 'Enter Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textColor), textAlign: TextAlign.center),
          const SizedBox(height: 15),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
            decoration: InputDecoration(
              prefixText: 'KSh ',
              prefixStyle: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00B140)),
              hintText: '237',
              hintStyle: TextStyle(fontSize: 40, color: Colors.grey[400]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00B140), width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF00B140), width: 3)),
              filled: true,
              fillColor: cardColor,
            ),
            onSubmitted: (_) => _calculate(),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B140),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
            ),
            child: Text(_isSwahili? 'HESABU' : 'CALCULATE', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 30),
          AnimatedOpacity(
            opacity: _showResult? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _showResult
             ? Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00B140), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        Text(_isWithdrawMode? (_isSwahili? 'Toa:' : 'Withdraw:') : (_isSwahili? 'Tuma:' : 'Send:'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text('KSh $_resultAmount', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Color(0xFF00B140))),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            _isWithdrawMode? (_isSwahili? 'Gharama: $_lostAmount bob' : 'Total cost: $_lostAmount bob')
                              : (_isSwahili? 'Unapoteza: $_lostAmount bob' : 'You lose: $_lostAmount bob'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red[700]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(_isSwahili? 'Agent yuko sawa ✅' : 'Agent is right ✅', style: const TextStyle(fontSize: 14, color: Color(0xFF00B140))),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _copyResult,
                              icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                              label: Text(_isSwahili? 'NAKILI' : 'COPY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00B140),
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton.icon(
                              onPressed: _shareResult,
                              icon: const Icon(Icons.share, color: Colors.white, size: 20),
                              label: Text(_isSwahili? 'TUMA' : 'SHARE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(bool isDark) {
    final cardColor = isDark? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark? Colors.white : Colors.black;

    return _history.isEmpty
     ? Center(child: Text(_isSwahili? 'Bado hakuna historia' : 'No history yet', style: TextStyle(color: textColor, fontSize: 18)))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00B140))),
                child: Text(_history[index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('M-PESA Smart Calc KE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF00B140),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSwahili? Icons.language : Icons.translate, color: Colors.white),
            onPressed: () => setState(() => _isSwahili =!_isSwahili),
          ),
          IconButton(
            icon: Icon(_isDarkMode? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () => setState(() => _isDarkMode =!_isDarkMode),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedTab == 0? _buildCalculator(_isDarkMode) : _buildHistory(_isDarkMode),
          ),
          // ← AD SECTION WITH ERROR MESSAGE
          if (_adError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[100],
              child: Text(_adError, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
            )
          else if (_isAdLoaded && _bannerAd!= null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            Container(
              height: 50,
              alignment: Alignment.center,
              child: const Text('Loading ad...', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        selectedItemColor: const Color(0xFF00B140),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.calculate), label: _isSwahili? 'Hesabu' : 'Calculator'),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: _isSwahili? 'Historia' : 'History'),
        ],
      ),
    );
  }
}
