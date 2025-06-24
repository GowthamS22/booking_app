int safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class BookingWithAll {
  String? id;
  String? bookingNo;
  String? customerId;
  int? total;
  int? subTotal;
  int? discount;
  int? gst;
  int? surcharge;
  int? grandTotal;
  String? paymentType;
  String? paymentStatus;
  String? status;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  dynamic deletedAt;
  String? createdBy;
  String? updatedBy;
  dynamic deletedBy;
  bool? isCancelled;
  bool? isShowoff;
  dynamic reason;
  List<BookingSlotNew>? bookingSlots;
  List<BookingPayment>? bookingPayments;
  List<BookingPayment>? bookingSlotsPayments;

  BookingWithAll({
    this.id,
    this.bookingNo,
    this.customerId,
    this.total,
    this.subTotal,
    this.discount,
    this.gst,
    this.surcharge,
    this.grandTotal,
    this.paymentType,
    this.paymentStatus,
    this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.isCancelled,
    this.isShowoff,
    this.reason,
    this.bookingSlots,
    this.bookingPayments,
    this.bookingSlotsPayments,
  });

  factory BookingWithAll.fromJson(Map<String, dynamic> json) => BookingWithAll(
    id: json["id"],
    bookingNo: json["booking_no"],
    customerId: json["customer_id"],
    total: safeInt(json["total"]),
    subTotal: safeInt(json["sub_total"]),
    discount: safeInt(json["discount"]),
    gst: safeInt(json["gst"]),
    surcharge: safeInt(json["surcharge"]),
    grandTotal: safeInt(json["grand_total"]),
    paymentType: json["payment_type"],
    paymentStatus: json["payment_status"],
    status: json["status"],
    notes: json["notes"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"],
    createdBy: json["created_by"],
    updatedBy: json["updated_by"],
    deletedBy: json["deleted_by"],
    isCancelled: json["is_cancelled"],
    isShowoff: json["is_showoff"],
    reason: json["reason"],
    bookingSlots: json["booking_slots"] == null ? [] : List<BookingSlotNew>.from(json["booking_slots"]!.map((x) => BookingSlotNew.fromJson(x))),
    bookingPayments: json["booking_payments"] == null ? [] : List<BookingPayment>.from(json["booking_payments"]!.map((x) => BookingPayment.fromJson(x))),
    bookingSlotsPayments: json["booking_slots_payments"] == null ? [] : List<BookingPayment>.from(json["booking_slots_payments"]!.map((x) => BookingPayment.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "booking_no": bookingNo,
    "customer_id": customerId,
    "total": total,
    "sub_total": subTotal,
    "discount": discount,
    "gst": gst,
    "surcharge": surcharge,
    "grand_total": grandTotal,
    "payment_type": paymentType,
    "payment_status": paymentStatus,
    "status": status,
    "notes": notes,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt,
    "created_by": createdBy,
    "updated_by": updatedBy,
    "deleted_by": deletedBy,
    "is_cancelled": isCancelled,
    "is_showoff": isShowoff,
    "reason": reason,
    "booking_slots": bookingSlots == null ? [] : List<dynamic>.from(bookingSlots!.map((x) => x.toJson())),
    "booking_payments": bookingPayments == null ? [] : List<dynamic>.from(bookingPayments!.map((x) => x.toJson())),
    "booking_slots_payments": bookingSlotsPayments == null ? [] : List<dynamic>.from(bookingSlotsPayments!.map((x) => x.toJson())),
  };
}

class BookingPayment {
  String? id;
  String? notes;
  int? total;
  String? status;
  String? bookingId;
  DateTime? createdAt;
  String? createdBy;
  dynamic deletedAt;
  dynamic deletedBy;
  DateTime? updatedAt;
  String? updatedBy;
  String? customerId;
  int? paidAmount;
  String? paymentVia;
  String? paymentType;
  String? paymentResponse;
  String? bookingSlotsId;
  String? bookingPaymentsId;

  BookingPayment({
    this.id,
    this.notes,
    this.total,
    this.status,
    this.bookingId,
    this.createdAt,
    this.createdBy,
    this.deletedAt,
    this.deletedBy,
    this.updatedAt,
    this.updatedBy,
    this.customerId,
    this.paidAmount,
    this.paymentVia,
    this.paymentType,
    this.paymentResponse,
    this.bookingSlotsId,
    this.bookingPaymentsId,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) => BookingPayment(
    id: json["id"],
    notes: json["notes"],
    total: safeInt(json["total"]),
    status: json["status"],
    bookingId: json["booking_id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    createdBy: json["created_by"],
    deletedAt: json["deleted_at"],
    deletedBy: json["deleted_by"],
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    updatedBy: json["updated_by"],
    customerId: json["customer_id"],
    paidAmount: safeInt(json["paid_amount"]),
    paymentVia: json["payment_via"],
    paymentType: json["payment_type"],
    paymentResponse: json["payment_response"],
    bookingSlotsId: json["booking_slots_id"],
    bookingPaymentsId: json["booking_payments_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "notes": notes,
    "total": total,
    "status": status,
    "booking_id": bookingId,
    "created_at": createdAt?.toIso8601String(),
    "created_by": createdBy,
    "deleted_at": deletedAt,
    "deleted_by": deletedBy,
    "updated_at": updatedAt?.toIso8601String(),
    "updated_by": updatedBy,
    "customer_id": customerId,
    "paid_amount": paidAmount,
    "payment_via": paymentVia,
    "payment_type": paymentType,
    "payment_response": paymentResponse,
    "booking_slots_id": bookingSlotsId,
    "booking_payments_id": bookingPaymentsId,
  };
}

class BookingSlotNew {
  String? id;
  int? price;
  String? status;
  String? courtId;
  DateTime? endTime;
  dynamic repeatId;
  dynamic slotType;
  String? bookingId;
  DateTime? createdAt;
  String? createdBy;
  dynamic deletedAt;
  dynamic deletedBy;
  String? serviceId;
  DateTime? startTime;
  DateTime? updatedAt;
  String? updatedBy;
  String? repeatDays;
  dynamic courtIndexId;
  PlatformStatus? platformStatus;
  dynamic repeatEndDate;
  dynamic repeatGroupId;
  bool? isExtendedBooking;

  BookingSlotNew({
    this.id,
    this.price,
    this.status,
    this.courtId,
    this.endTime,
    this.repeatId,
    this.slotType,
    this.bookingId,
    this.createdAt,
    this.createdBy,
    this.deletedAt,
    this.deletedBy,
    this.serviceId,
    this.startTime,
    this.updatedAt,
    this.updatedBy,
    this.repeatDays,
    this.courtIndexId,
    this.platformStatus,
    this.repeatEndDate,
    this.repeatGroupId,
    this.isExtendedBooking,
  });

  factory BookingSlotNew.fromJson(Map<String, dynamic> json) => BookingSlotNew(
    id: json["id"],
    price: safeInt(json["price"]),
    status: json["status"],
    courtId: json["court_id"],
    endTime: json["end_time"] == null ? null : DateTime.parse(json["end_time"]),
    repeatId: json["repeat_id"],
    slotType: json["slot_type"],
    bookingId: json["booking_id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    createdBy: json["created_by"],
    deletedAt: json["deleted_at"],
    deletedBy: json["deleted_by"],
    serviceId: json["service_id"],
    startTime: json["start_time"] == null ? null : DateTime.parse(json["start_time"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    updatedBy: json["updated_by"],
    repeatDays: json["repeat_days"],
    courtIndexId: json["court_index_id"],
    platformStatus: json["platform_status"] == null ? null : PlatformStatus.fromJson(json["platform_status"]),
    repeatEndDate: json["repeat_end_date"],
    repeatGroupId: json["repeat_group_id"],
    isExtendedBooking: json["is_extended_booking"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "price": price,
    "status": status,
    "court_id": courtId,
    "end_time": endTime?.toIso8601String(),
    "repeat_id": repeatId,
    "slot_type": slotType,
    "booking_id": bookingId,
    "created_at": createdAt?.toIso8601String(),
    "created_by": createdBy,
    "deleted_at": deletedAt,
    "deleted_by": deletedBy,
    "service_id": serviceId,
    "start_time": startTime?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "updated_by": updatedBy,
    "repeat_days": repeatDays,
    "court_index_id": courtIndexId,
    "platform_status": platformStatus?.toJson(),
    "repeat_end_date": repeatEndDate,
    "repeat_group_id": repeatGroupId,
    "is_extended_booking": isExtendedBooking,
  };
}

class PlatformStatus {
  String? id;
  Sports? sports;
  bool? status;
  String? sportId;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? platformId;

  PlatformStatus({
    this.id,
    this.sports,
    this.status,
    this.sportId,
    this.createdAt,
    this.updatedAt,
    this.platformId,
  });

  factory PlatformStatus.fromJson(Map<String, dynamic> json) => PlatformStatus(
    id: json["id"],
    sports: json["sports"] == null ? null : Sports.fromJson(json["sports"]),
    status: json["status"],
    sportId: json["sport_id"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    platformId: json["platform_id"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "sports": sports?.toJson(),
    "status": status,
    "sport_id": sportId,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "platform_id": platformId,
  };
}

class Sports {
  String? sportName;

  Sports({
    this.sportName,
  });

  factory Sports.fromJson(Map<String, dynamic> json) => Sports(
    sportName: json["sport_name"],
  );

  Map<String, dynamic> toJson() => {
    "sport_name": sportName,
  };
}