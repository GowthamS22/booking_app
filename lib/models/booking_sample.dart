// booking_sample.dart
class BookingSample {
  final String id;
  final String bookingNo;
  final String customerId;
  final double total;
  final String paymentStatus;
  final DateTime createdAt;
  final List<BookingSampleSlot> slots;
  final CustomerSample? customer;

  BookingSample({
    required this.id,
    required this.bookingNo,
    required this.customerId,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
    required this.slots,
    this.customer,
  });

  factory BookingSample.fromJson(Map<String, dynamic> json) {
    return BookingSample(
      id: json['id'],
      bookingNo: json['booking_no'],
      customerId: json['customer_id'],
      total: json['total']?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'],
      createdAt: DateTime.parse(json['created_at']),
      slots: [],
      customer: json['customers'] != null ? CustomerSample.fromJson(json['customers']) : null,
    );
  }
}

class BookingSampleSlot {
  final String id;
  final String bookingId;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final String status;

  BookingSampleSlot({
    required this.id,
    required this.bookingId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
  });

  factory BookingSampleSlot.fromJson(Map<String, dynamic> json) {
    return BookingSampleSlot(
      id: json['id'],
      bookingId: json['booking_id'],
      courtId: json['court_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      price: json['price']?.toDouble() ?? 0.0,
      status: json['status'],
    );
  }
}

class CustomerSample {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? email;

  CustomerSample({
    required this.id,
    this.firstName,
    this.lastName,
    this.mobile,
    this.email,
  });

  factory CustomerSample.fromJson(Map<String, dynamic> json) {
    return CustomerSample(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      mobile: json['mobile'],
      email: json['email'],
    );
  }

  String get fullName => '$firstName';
}