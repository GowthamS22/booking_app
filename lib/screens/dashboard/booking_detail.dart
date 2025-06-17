// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:lucide_icons/lucide_icons.dart';

// import 'dashboardScreen.dart';

// class BookingDetailsDialog extends StatelessWidget {
//   final Booking booking;

//   const BookingDetailsDialog({Key? key, required this.booking})
//     : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     //final List<Map<String, dynamic>> purchaseItems = [];
//     final List<Map<String, dynamic>> purchaseItems = [
//       {'name': 'Energy Drink', 'qty': 2, 'price': 3646.32},
//       {'name': 'Shuttlecock', 'qty': 1, 'price': 65.98},
//       {'name': 'Yoga Mat', 'qty': 1, 'price': 129.99},
//       {'name': 'Protein Bar', 'qty': 2, 'price': 79.50},
//       {'name': 'Tennis Racket', 'qty': 1, 'price': 199.00},
//       {'name': 'Boxing Gloves', 'qty': 4, 'price': 89.99},
//       {'name': 'Foam Roller', 'qty': 1, 'price': 34.99},
//     ];
//     double total = purchaseItems.fold(
//       0,
//       (sum, item) => sum + (item['price'] as double),
//     );
//     return Dialog(
//       backgroundColor: Colors.white,
//       insetPadding: const EdgeInsets.all(20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: 
//       Container(
//         padding: const EdgeInsets.all(20),
//         width: 400,
//         child: SingleChildScrollView(
//           child:
//            Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         booking.customer,
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       Text(
//                         "0401 275 544",
//                         style: GoogleFonts.poppins(
//                           fontSize: 12.5,
//                           color: Colors.grey,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Text.rich(
//                     TextSpan(
//                       children: [
//                         TextSpan(
//                           text: 'Remaining Time\n',
//                           style: GoogleFonts.poppins(
//                             fontSize: 13,
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         TextSpan(
//                           text: '15:00',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: Colors.black,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade100,
//                       border: Border.all(color: Colors.red.shade300),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           "No Show",
//                           style: GoogleFonts.poppins(
//                             fontSize: 13,
//                             color: Colors.red,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(width: 6),
//                         Icon(LucideIcons.userX, color: Colors.red, size: 18),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const Divider(height: 32),

//               /// Booking Details
//               Text(
//                 "Booking Details",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.black,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 "Current booking informations",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12.5,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Booking #${booking.id}",
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.black,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             bookingDetailRow(
//                               LucideIcons.gamepad2,
//                               "Sport",
//                               booking.game,
//                             ),
//                             const SizedBox(height: 12),
//                             bookingDetailRow(
//                               LucideIcons.clock,
//                               "Time",
//                               booking.time,
//                             ),
//                             const SizedBox(height: 12),
//                             bookingDetailRow(
//                               LucideIcons.timer,
//                               "Extended Time",
//                               "---",
//                             ),
//                           ],
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             bookingDetailRow(
//                               LucideIcons.scanLine,
//                               "Court",
//                               "Court 01",
//                             ),
//                             const SizedBox(height: 12),
//                             bookingDetailRow(
//                               LucideIcons.timer,
//                               "Duration",
//                               booking.duration,
//                             ),
//                             const SizedBox(height: 12),
//                             bookingDetailRow(
//                               LucideIcons.dollarSign,
//                               "Payment",
//                               "Unpaid",
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     TextButton(
//                       onPressed: () {},
//                       style: TextButton.styleFrom(
//                         backgroundColor: const Color(0xFFF4F3FF),
//                         foregroundColor: const Color(0xFF6C63FF),
//                         side: const BorderSide(
//                           color: Color(0xFF6C63FF),
//                           width: 1.5,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         minimumSize: const Size.fromHeight(48),
//                       ),
//                       child: const Text(
//                         'Extend Time',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),
//               Text(
//                 "Purchase Details",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.black,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 "Current purchase order informations",
//                 style: GoogleFonts.poppins(
//                   fontSize: 12.5,
//                   color: Colors.grey,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               purchaseItems.isEmpty
//                   ? Container(
//                     height: 60,
//                     alignment: Alignment.center,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       "No purchase has been made",
//                       style: GoogleFonts.poppins(
//                         fontSize: 12.5,
//                         color: Colors.grey,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   )
//                   : Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Text(
//                               "Order ID #6475",
//                               style: GoogleFonts.poppins(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const Spacer(),
//                             Text(
//                               "11:04:34 AM",
//                               style: GoogleFonts.poppins(
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const Divider(),
//                         ...purchaseItems.map((item) {
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 4),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     item['name'],
//                                     style: GoogleFonts.poppins(fontSize: 12),
//                                   ),
//                                 ),
//                                 Text(
//                                   '${item['qty']}',
//                                   style: GoogleFonts.poppins(fontSize: 12),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Text(
//                                   '\$${item['price'].toStringAsFixed(2)}',
//                                   style: GoogleFonts.poppins(fontSize: 12),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),
//                         const Divider(),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 "Grand Total",
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ),
//                             Text(
//                               total.toStringAsFixed(2),
//                               //currencyFormat.format(total),
//                               style: GoogleFonts.poppins(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   OutlinedButton(onPressed: () {}, child: const Text("Cancel")),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("New Session"),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {},
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("Pay Now"),
//                   ),
//                 ],
//               ),
//             ],
//           ),
       
//         ),
//       ),
//     );
//   }

//   Widget bookingDetailRow(IconData icon, String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, size: 16, color: Colors.grey[600]),
//         const SizedBox(width: 6),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 12.5,
//                 color: Colors.grey,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               value,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: Colors.black,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
