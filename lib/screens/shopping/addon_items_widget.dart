import 'dart:convert';
import 'dart:math';

import 'package:booking_app/controllers/PosOrderController.dart';
import 'package:booking_app/models/category.dart';
import 'package:booking_app/models/products.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(home: AddonItemsWidget()));
}

class AddonItemsWidget extends StatefulWidget {
  const AddonItemsWidget({Key? key}) : super(key: key);

  @override
  State<AddonItemsWidget> createState() => _AddonItemsWidgetState();
}

class _AddonItemsWidgetState extends State<AddonItemsWidget> {

  static const String _prefsCartKey = 'shopping_cart';
  static const String _prefsOrderNotesKey = 'order_notes';
  static const String _prefsOrderIdKey = 'order_id';

  List<Category> categories = [];
  List<Products> products   = [];
  Category? selectedCategory;
  List<CartItem> cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isLoading = true;
  String _orderNotes = '';
  String _tempOrderId = '';

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load categories
      final categoriesJson = prefs.getString('categories');
      if (categoriesJson != null) {
        final List<dynamic> categoryData = jsonDecode(categoriesJson);
        categories = categoryData.map((json) => Category.fromJson(json)).toList();
      }

      // Load products
      final productsJson = prefs.getString('products');
      if (productsJson != null) {
        final List<dynamic> productData = jsonDecode(productsJson);
        products = productData.map((json) => Products.fromJson(json)).toList();
      }

      // Set default selected category
      if (categories.isNotEmpty) {
        selectedCategory = categories.firstWhere(
              (cat) => cat.name == "Shuttlecock",
          orElse: () => categories.first,
        );
      }

    } catch (e) {
      print('Error loading data: $e');
      // Consider showing an error message to the user
    }
  }

  List<Products> get filteredProducts {
    // First filter by category
    List<Products> filtered = selectedCategory == null
        ? products
        : products.where((p) => p.categoryId == selectedCategory!.id).toList();

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
      p.name.toLowerCase().contains(_searchQuery) ||
          p.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _clearPrefsData();
    _clearExistingOrderData();
    _loadData().then((_) async {
      await _loadOrderIdFromPrefs();
      await _loadOrderNotesFromPrefs();
      await _loadCartFromPrefs();
      setState(() => isLoading = false);
    });
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _clearPrefsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCartKey);
    await prefs.remove(_prefsOrderNotesKey);
    await prefs.remove(_prefsOrderIdKey);
  }

  void _clearExistingOrderData() {
    final orderController = Get.find<PosOrderController>();
    orderController.clearOrder();
  }

  Future<void> _loadOrderIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_prefsOrderIdKey);
    if (savedId == null) {
      _generateTempOrderId();
    } else {
      setState(() {
        _tempOrderId = savedId;
      });
    }
  }

  void _generateTempOrderId() {
    final random = Random();
    setState(() {
      _tempOrderId = 'TMP${random.nextInt(900) + 100}';
      _saveOrderIdToPrefs();
    });
  }

  Future<void> _saveOrderIdToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOrderIdKey, _tempOrderId);
  }

  Future<void> _loadOrderNotesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotes = prefs.getString(_prefsOrderNotesKey) ?? '';
    });
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_prefsCartKey);
    if (cartJson != null) {
      final List<dynamic> cartData = jsonDecode(cartJson);
      setState(() {
        cart = cartData.map((json) => CartItem.fromJson(json)).toList();
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void addToCart(Products product) {
    final index = cart.indexWhere((e) => e.product.id == product.id);
    setState(() {
      if (index != -1) {
        cart[index].quantity++;
        cart[index].updateAppliedPrice();
      } else {
        cart.add(CartItem(product: product));
      }
      _saveCartToPrefs();
    });
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(cart.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsCartKey, cartJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Need Accessories?", style: TextStyle(fontSize: 25),),
              ElevatedButton(
                onPressed: () {

                },
                child: const Text("View More", style: TextStyle(fontSize: 22, color: Colors.black54),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(200, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10,),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 250,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white
                  ),
                  child: InkWell(
                    onTap: () => addToCart(product),
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.network(
                            product.imageUrl.toString(),
                            errorBuilder: (context, error, stackTrace) => Image.network(
                              'https://placehold.co/150x100/png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


