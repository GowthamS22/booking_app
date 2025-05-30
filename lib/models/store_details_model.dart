class OpeningTime {
  final String day;
  final String startTime;
  final String endTime;
  final bool isActive;

  OpeningTime({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory OpeningTime.fromJson(Map<String, dynamic> json) {
    return OpeningTime(
      day: json['day'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
    };
  }
}

class StoreDetails {
  final String id;
  final String name;
  final List<OpeningTime> openingTimes;

  StoreDetails({
    required this.id,
    required this.name,
    required this.openingTimes,
  });

  factory StoreDetails.fromJson(Map<String, dynamic> json) {
    var openingTimesList =
        (json['opening_times'] as List)
            .map((e) => OpeningTime.fromJson(e))
            .toList();

    return StoreDetails(
      id: json['id'],
      name: json['name'],
      openingTimes: openingTimesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'opening_times': openingTimes.map((e) => e.toJson()).toList(),
    };
  }
}

class CourtViewTimeSlots {
  final String time;
  final bool isPeak;
  final double price;

  CourtViewTimeSlots({
    required this.time,
    required this.isPeak,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'isPeak': isPeak,
    'price': price,
  };
}
