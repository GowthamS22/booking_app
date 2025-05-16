import 'package:flutter/material.dart';

class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final List<String> paymentMethods = [
    'EFTPOS',
    'On Account/Void',
    'CASH',
    'MIXED',
  ];
  String selectedMethod = 'CASH';

  final List<String> cashOptions = [
    '\$20.00',
    '\$10',
    '\$20',
    '\$50',
    '\$100',
    'Custom',
  ];

  double billAmount = 20.0;
  double totalPaid = 0.0;
  bool receipt = true;

  void _addPayment(double amount) {
    setState(() {
      totalPaid += amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F355F), // Navy blue
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Items count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        child: Text(
                          'Items : 7',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Split bill button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F355F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.table_rows_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Split Bill',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  // Category Dropdown/Expansion
                  ExpansionTile(
                    title: Text('Drinks'),
                    children: [
                      ListTile(
                        title: Text('Butter Milk x 1'),
                        trailing: Text('\$4.00'),
                      ),
                      ListTile(
                        title: Text('Filter Coffee x 1'),
                        trailing: Text('\$7.00'),
                      ),
                      ListTile(
                        title: Text('Soft Drink x 1'),
                        trailing: Text('\$3.00'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('Sweets & Snacks'),
                    children: [
                      ListTile(
                        title: Text('Mango Lassi x 1'),
                        trailing: Text('\$6.00'),
                      ),
                    ],
                  ),
                  Spacer(),
                  // Totals
                  ListTile(title: Text('Total'), trailing: Text('\$20.00')),
                  ListTile(title: Text('GST Incl.'), trailing: Text('\$2.00')),
                  ListTile(
                    title: Text('Grand Total'),
                    trailing: Text('\$20.00'),
                  ),
                ],
              ),
            ),
          ),
          // Right Panel
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Amounts
                  _buildAmountSummary(),
                  SizedBox(height: 20),
                  // Payment Methods
                  _buildPaymentOptions(),
                  if (selectedMethod == 'CASH') ...[
                    SizedBox(height: 50),
                    _buildCashButtons(),
                  ],

                  const SizedBox(height: 20),

                  // Notes and Discount
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(hintText: 'Notes'),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text('Discount'),
                        ),
                      ],
                    ),
                  ),
                  // Receipt toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Receipt'),
                      Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: Colors.indigo.shade900,
                      ),
                    ],
                  ),
                  // Payment Complete Button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        'Payment Complete',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        minimumSize: Size(20, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummary() {
    double balance = billAmount - totalPaid;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _amountColumn('Bill Amount', billAmount),
        _amountColumn('Total Paid', totalPaid),
        _amountColumn('Balance', balance),
      ],
    );
  }

  Widget _amountColumn(String label, double amount) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: label == 'Balance' && amount > 0 ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          paymentMethods.map((method) {
            final isSelected = selectedMethod == method;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.white : Colors.grey[100],
                side: BorderSide(
                  color:
                      isSelected ? Colors.indigo.shade900 : Colors.transparent,
                ),
                minimumSize: Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
              ),
              onPressed: () {
                setState(() => selectedMethod = method);
              },
              child: Text(
                method,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCashButtons() {
    final cashAmounts = [20, 10, 20, 50, 100];
    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            ...cashAmounts.map(
              (amt) => ElevatedButton(
                onPressed: () => _addPayment(amt.toDouble()),
                child: Text('\$$amt', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  minimumSize: Size(50, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _showCustomAmountDialog,
              child: Text('Custom', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                minimumSize: Size(50, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _showCustomAmountDialog() {
    String customValue = '';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Enter a Custom Value',
                style: TextStyle(fontSize: 14),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customValue.isEmpty ? '0.00' : customValue,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  ..._buildKeypad(setState, (val) {
                    setState(() {
                      if (val == '←') {
                        if (customValue.isNotEmpty) {
                          customValue = customValue.substring(
                            0,
                            customValue.length - 1,
                          );
                        }
                      } else {
                        customValue += val;
                      }
                    });
                  }),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (customValue.isNotEmpty) {
                      _addPayment(double.tryParse(customValue) ?? 0);
                    }
                  },

                  child: const Text(
                    'Enter Amount',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildKeypad(
    void Function(void Function()) setState,
    Function(String) onPressed,
  ) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '←'],
    ];

    return keys.map((row) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            row.map((key) {
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: SizedBox(
                  width: 70,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => onPressed(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              );
            }).toList(),
      );
    }).toList();
  }
}
