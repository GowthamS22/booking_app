import 'package:booking_app/models/products.dart';

class Orders {
  String? id;
  String? tokenNumber;
  dynamic uniqueId;
  DateTime? orderDate;
  String? orderType;
  List<CartItem>? cartItems;
  BillDetails? billDetails;
  String? transactionData;
  bool? closed;
  dynamic bookingId;
  dynamic customerId;
  //double? total;
  //double? paidAmount;
  String? paymentType;
  String? paymentVia;
  dynamic paymentResponse;
  String? orderStatus;
  dynamic notes;
  DateTime? createdAt;
  dynamic updatedAt;
  dynamic deletedAt;
  dynamic createdBy;
  dynamic updatedBy;
  dynamic deletedBy;

  Orders({
    this.id,
    this.tokenNumber,
    this.uniqueId,
    this.orderDate,
    this.orderType,
    this.cartItems,
    this.billDetails,
    this.transactionData,
    this.closed,
    this.bookingId,
    this.customerId,
    //this.total,
    //this.paidAmount,
    this.paymentType,
    this.paymentVia,
    this.paymentResponse,
    this.orderStatus,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
  });

  factory Orders.fromJson(Map<String, dynamic> json) => Orders(
    id: json["id"],
    tokenNumber: json["token_number"],
    uniqueId: json["unique_id"],
    orderDate: json["order_date"] == null ? null : DateTime.parse(json["order_date"]),
    orderType: json["order_type"],
    cartItems: json["cart_items"] == null ? [] : List<CartItem>.from(json["cart_items"]!.map((x) => CartItem.fromJson(x))),
    billDetails: json["bill_details"] == null ? null : BillDetails.fromJson(json["bill_details"]),
    transactionData: json["transaction_data"],
    closed: json["closed"],
    bookingId: json["booking_id"],
    customerId: json["customer_id"],
    //total: json["total"]?.toDouble(),
    //paidAmount: json["paid_amount"],
    paymentType: json["payment_type"],
    paymentVia: json["payment_via"],
    paymentResponse: json["payment_response"],
    orderStatus: json["order_status"],
    notes: json["notes"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"],
    deletedAt: json["deleted_at"],
    createdBy: json["created_by"],
    updatedBy: json["updated_by"],
    deletedBy: json["deleted_by"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "token_number": tokenNumber,
    "unique_id": uniqueId,
    "order_date": "${orderDate!.year.toString().padLeft(4, '0')}-${orderDate!.month.toString().padLeft(2, '0')}-${orderDate!.day.toString().padLeft(2, '0')}",
    "order_type": orderType,
    "cart_items": cartItems == null ? [] : List<dynamic>.from(cartItems!.map((x) => x.toJson())),
    "bill_details": billDetails?.toJson(),
    "transaction_data": transactionData,
    "closed": closed,
    "booking_id": bookingId,
    "customer_id": customerId,
    //"total": total,
    //"paid_amount": paidAmount,
    "payment_type": paymentType,
    "payment_via": paymentVia,
    "payment_response": paymentResponse,
    "order_status": orderStatus,
    "notes": notes,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt,
    "deleted_at": deletedAt,
    "created_by": createdBy,
    "updated_by": updatedBy,
    "deleted_by": deletedBy,
  };
}

class BillDetails {
  double? price;
  double? taxes;
  double? discount;
  String? orderId;
  double? surcharge;
  double? billAmount;
  double? paidAmount;
  String? paymentType;
  String? paymentNotes;
  double? balanceAmount;

  BillDetails({
    this.price,
    this.taxes,
    this.discount,
    this.orderId,
    this.surcharge,
    this.billAmount,
    this.paidAmount,
    this.paymentType,
    this.paymentNotes,
    this.balanceAmount,
  });

  factory BillDetails.fromJson(Map<String, dynamic> json) => BillDetails(
    price: json["price"]?.toDouble(),
    taxes: json["taxes"]?.toDouble(),
    discount: json["discount"],
    orderId: json["order_id"],
    surcharge: json["surcharge"],
    billAmount: json["billAmount"]?.toDouble(),
    paidAmount: json["paidAmount"],
    paymentType: json["paymentType"],
    paymentNotes: json["paymentNotes"],
    balanceAmount: json["balanceAmount"],
  );

  Map<String, dynamic> toJson() => {
    "price": price,
    "taxes": taxes,
    "discount": discount,
    "order_id": orderId,
    "surcharge": surcharge,
    "billAmount": billAmount,
    "paidAmount": paidAmount,
    "paymentType": paymentType,
    "paymentNotes": paymentNotes,
    "balanceAmount": balanceAmount,
  };
}