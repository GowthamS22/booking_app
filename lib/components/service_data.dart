import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class ServiceData extends ChangeNotifier {
  List<Map<String, dynamic>> _serviceList = [];

  List<Map<String, dynamic>> get serviceList => _serviceList;

  Future<void> fetchServiceList(String centerSlug) async {
    _serviceList.clear();
    QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
        .collection(centerSlug)
        .doc('services')
        .collection('service')
        .where('active', isEqualTo: 1)
        .orderBy('displayOrder', descending: false)
        .get();
    for (var service in serviceSnapshot.docs) {
      _serviceList.add({
        'id': service.id,
        'name': service['name'],
        'icon': service['icon'],
      });
    }
    notifyListeners();
  }
}
