class Booking {

  String? id;
  String? userId;
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
      this.userId,
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
  DateTime? updatedAt;// End date

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
      this.paymentStatus
      );

}