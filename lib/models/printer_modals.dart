import 'package:get/get.dart';

class PrinterModel {
  String name;
  String ip;
  String port;
  RxBool isEditing;

  PrinterModel({
    required this.name,
    required this.ip,
    required this.port,
    bool isEditing = false,
  }) : this.isEditing = isEditing.obs;

  factory PrinterModel.fromJson(Map<String, dynamic> json) => PrinterModel(
    name: json['name'],
    ip: json['ip'],
    port: json['port'],
    isEditing: json['isEditing'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'ip': ip,
    'port': port,
    'isEditing': isEditing.value,
  };
}
