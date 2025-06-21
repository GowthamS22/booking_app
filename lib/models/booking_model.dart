class Booking {
  String? id;
  String? bookingNo;
  String? customerid;
  String? name;
  String? mobile;
  String? email;
  String? notes;
  double? subTotal;
  double? discount;
  double? gst;
  double? total;
  String? paymentType;
  String? paymentStatus;
  String? status;
  List<BookingSlot> bookingSlot;
  String? createdBy;
  String? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  Booking(
    this.id,
    this.bookingNo,
    this.customerid,
    this.name,
    this.mobile,
    this.email,
    this.notes,
    this.subTotal,
    this.discount,
    this.gst,
    this.total,
    this.paymentType,
    this.paymentStatus,
    this.status,
    this.bookingSlot,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  );
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({required this.startTime, required this.endTime});
}

class BookingModel {
  final String? bookingNo;
  final double? grandTotal;
  final String? customerName;
  final String? customerMobile;
  final String? courtName;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? paymentStatus;
  final String? sportname;
  final String? platformId;

  BookingModel({
    this.bookingNo,
    this.grandTotal,
    this.customerName,
    this.customerMobile,
    this.courtName,
    this.startTime,
    this.endTime,
    this.paymentStatus,
    this.sportname,
    this.platformId,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final booking = json['bookings'] as Map<String, dynamic>?;
    final customer = booking?['customers'] as Map<String, dynamic>?;
    final platformStatus = json['platform_status'] as Map<String, dynamic>?;
    final sports = platformStatus?['sports'] as Map<String, dynamic>?;
    final platformId = platformStatus?['platform_id']?.toString() ?? '';
    return BookingModel(
      bookingNo: booking?['booking_no'] as String?,
      grandTotal: (booking?['grand_total'] as num?)?.toDouble(),
      customerName:
          customer != null
              ? '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'
                  .trim()
              : null,
      customerMobile: customer?['mobile'] as String?,
      courtName: sports?['platform_name'] as String?,
      startTime:
          json['start_time'] != null
              ? DateTime.tryParse(json['start_time'])
              : null,
      endTime:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      paymentStatus: booking?['payment_status'] as String?,
      sportname: sports?['sport_name'] as String,
      platformId: platformId,
    );
  }
}

class BookingPayments {
  String? id;
  String? userId;
  DateTime? date;
  String? paymentType;
  String? paymentVia;
  double? subTotal;
  double? discount;
  double? gst;
  double? total;
  String? paidAmount;
  String? balance;
  double? status;
  String? createdBy;
  String? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  BookingPayments(
    this.id,
    this.userId,
    this.date,
    this.paymentType,
    this.paymentVia,
    this.subTotal,
    this.discount,
    this.gst,
    this.total,
    this.paidAmount,
    this.balance,
    this.status,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  );
}

class BookingSlot {
  String? id;
  String? userId;
  String? name;
  String? mobile;
  String? bookingId;
  String? subBookingId;
  DateTime? date;
  String? service;
  String? serviceId;
  String? court;
  String? courtId;
  DateTime? startTime;
  DateTime? endTime;
  double? price;
  String? slotType; //Normal | Repeated | Repeat-Item
  String? repeatDays; // Days string
  DateTime? repeatEnd;
  String? repeatId;
  String? repeatGroupId;
  String? paymentStatus;
  String? status;
  String? createdBy;
  String? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt; // End date
  String? membershipPlanId;
  String? bookingNo;
  double? total;
  String? platformIndex;
  bool? is_extended_booking;

  BookingSlot({
    this.id,
    this.userId,
    this.name,
    this.mobile,
    this.bookingId,
    this.subBookingId,
    this.date,
    this.service,
    this.serviceId,
    this.court,
    this.courtId,
    this.startTime,
    this.endTime,
    this.price,
    this.slotType,
    this.repeatDays,
    this.repeatEnd,
    this.repeatId,
    this.repeatGroupId,
    this.paymentStatus,
    this.status,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.membershipPlanId,
    this.bookingNo,
    this.total,
    this.platformIndex,
    this.is_extended_booking,
  });
}

class BookingSlotPayments {
  String? id;
  String? bookingPaymentId;
  String? bookingId;
  String? subBookingId;
  String? paymentType;
  String? total;
  String? paidAmount;
  String? balance;
  double? status;
  String? createdBy;
  String? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  BookingSlotPayments(
    this.id,
    this.bookingPaymentId,
    this.bookingId,
    this.subBookingId,
    this.paymentType,
    this.total,
    this.paidAmount,
    this.balance,
    this.status,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  );
}

class upComingBooking {
  String? subBookingId;
  String? bookingId;
  String? game;
  String? court;
  DateTime? startTime;
  DateTime? endTime;
  double? price;
  String? status;
  String? paymentStatus;

  upComingBooking(
    this.subBookingId,
    this.bookingId,
    this.game,
    this.court,
    this.startTime,
    this.endTime,
    this.price,
    this.status,
    this.paymentStatus,
  );
}

class BookingInfo {
  final String courtName;
  final DateTime selectedDateTime;
  List<String> selectedDays;
  DateTime? repeatUntil;
  bool sameLikeAbove;
  String bookingId;
  final List<BookingSubSlotInfo> subSlots;

  BookingInfo({
    required this.courtName,
    required this.selectedDateTime,
    this.selectedDays = const [],
    this.repeatUntil,
    this.sameLikeAbove = false,
    required this.bookingId,
    required this.subSlots,
  });
}

class BookingSubSlotInfo {
  final String startTime;
  final String endTime;
  final double price;
  final bool isPeak;

  BookingSubSlotInfo({
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isPeak,
  });
}
