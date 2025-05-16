class MembershipDiscount {
  String? id;
  double? minimumSpend;
  double? discount;
  DateTime? createdAt;

  MembershipDiscount(this.id, this.minimumSpend, this.discount, this.createdAt);
}

class MembershipPlan {
  String? id;
  String name;
  double price;
  int validDays;
  //List<MembershipDiscount>? discounts;
  double discount;
  bool active;
  DateTime createdAt;

  MembershipPlan({
    this.id,
    required this.name,
    required this.price,
    required this.validDays,
    //this.discounts,
    required this.discount,
    required this.active,
    required this.createdAt,
  });
}