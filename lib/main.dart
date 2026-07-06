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
          if (calculatedFee != null) ...[
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
                        Text(transactionType == 'TUMA' ? 'Jumla ya Kulipa:' : 'Utapata:', 
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
              label: Text('DIAL *334# TO ${transactionType == 'TUMA' ? 'SEND' : 'WITHDRAW'}', 
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
          SizedBox(height: 80)
        ],
      ),
    );
  }
