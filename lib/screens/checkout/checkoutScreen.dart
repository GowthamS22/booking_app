import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPayment = 'EPTPOS';
  String selectedAmount = '\$100';
  bool isReceipt = true;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopSummary(),
            const SizedBox(height: 16),
            _buildPaymentMethods(),
            const SizedBox(height: 16),
            _buildAmountButtons(),
            const SizedBox(height: 16),
            _buildDiscountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSummary() {
    return Row(
      children: [
        _summaryBox('Bill Amount', '\$121.11'),
        _divider(),
        _summaryBox('Total Paid', '\$00.00'),
        _divider(),
        _summaryBox('Balance', '\$53.66', highlight: true),
      ],
    );
  }

  Widget _summaryBox(String title, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFF6366F1) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 48, color: Colors.grey.shade300);

  Widget _buildPaymentMethods() {
    final List<Map<String, dynamic>> methods = [
      {'label': 'EPTPOS', 'icon': Icons.credit_card},
      {'label': 'On Acc. / Void', 'icon': Icons.description},
      {'label': 'Cash', 'icon': Icons.attach_money},
    ];

    return Row(
      children:
          methods.map((method) {
            final bool selected = method['label'] == selectedPayment;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedPayment = method['label']),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF0F4FF) : Colors.white,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        method['icon'],
                        color: selected ? const Color(0xFF6366F1) : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        method['label'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              selected
                                  ? const Color(0xFF6366F1)
                                  : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAmountButtons() {
    final List<String> amounts = [
      '\$10',
      '\$20',
      '\$50',
      '\$100',
      'Exact',
      'Custom',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children:
          amounts.map((amount) {
            final bool isSelected = amount == selectedAmount;
            return GestureDetector(
              onTap: () => setState(() => selectedAmount = amount),
              child: Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? const Color(0xFF6366F1) : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Discount Notes',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$15 Discount Applied',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Remove Discount',
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    'Receipt',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isReceipt,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) => setState(() => isReceipt = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
