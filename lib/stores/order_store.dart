// lib/stores/order_store.dart
import 'package:flutter/material.dart';
import 'package:booking_app/models/products.dart';

class OrderStore extends ChangeNotifier {
  String _orderId = '';
  List<CartItem> _cartItems = [];
  String _orderNotes = '';
  double _total = 0.0;

  // Getters
  String get orderId => _orderId;
  List<CartItem> get cartItems => _cartItems;
  String get orderNotes => _orderNotes;
  double get total => _total;

  // Update all order data
  void updateOrder(String id, List<CartItem> items, String notes, double total) {
    _orderId = id;
    _cartItems = items;
    _orderNotes = notes;
    _total = total;
    notifyListeners();
  }

  // Clear order
  void clearOrder() {
    _orderId = '';
    _cartItems = [];
    _orderNotes = '';
    _total = 0.0;
    notifyListeners();
  }
}