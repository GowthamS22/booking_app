import 'dart:convert';
import 'dart:math';
import 'package:booking_app/controllers/PosOrderController.dart';
import 'package:booking_app/controllers/orders_list_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:booking_app/stores/order_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booking_app/config/palette.dart';
import 'package:booking_app/models/category.dart';
import 'package:booking_app/models/products.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with SingleTickerProviderStateMixin {

  final OrdersListController ordersListController = Get.put(OrdersListController());

  // SharedPreferences keys
  static const String _prefsCartKey = 'shopping_cart';
  static const String _prefsOrderNotesKey = 'order_notes';
  static const String _prefsOrderIdKey = 'order_id';

  List<Category> categories = [];
  List<Products> products = [];
  Category? selectedCategory;
  List<CartItem> cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isLoading = true;
  String _orderNotes = '';
  String _tempOrderId = '';
  DateTime selectedDateTime = DateTime.now();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _clearExistingOrderData() {
    final orderController = Get.find<PosOrderController>();
    orderController.clearOrder();
  }

  void _generateTempOrderId() {
    final random = Random();
    setState(() {
      _tempOrderId = 'TMP${random.nextInt(900) + 100}';
      _saveOrderIdToPrefs();
    });
  }

  // SharedPreferences save/load methods
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(cart.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsCartKey, cartJson);
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

  Future<void> _saveOrderNotesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOrderNotesKey, _orderNotes);
  }

  Future<void> _loadOrderNotesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotes = prefs.getString(_prefsOrderNotesKey) ?? '';
    });
  }

  Future<void> _saveOrderIdToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOrderIdKey, _tempOrderId);
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

  Future<void> _clearPrefsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCartKey);
    await prefs.remove(_prefsOrderNotesKey);
    await prefs.remove(_prefsOrderIdKey);
  }

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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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

  void addToCart(Products product) {
    final index = cart.indexWhere((e) => e.product.id == product.id);
    setState(() {
      if (index != -1) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
      _saveCartToPrefs();
    });
  }

  void incrementQty(CartItem item) {
    setState(() {
      item.quantity++;
      _saveCartToPrefs();
    });
  }

  void decrementQty(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
      _saveCartToPrefs();
    });
  }

  double get total => cart.fold(0, (sum, item) => sum + double.parse(item.product.price) * item.quantity);

  Future<void> _showOrderNotesDialog(BuildContext context) async {
    final TextEditingController notesController =
    TextEditingController(text: _orderNotes);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
        title: const Text('Order Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Special instructions for the entire order...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _orderNotes = notesController.text;
                _saveOrderNotesToPrefs();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context) {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart before merging!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Merge Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Merge purchase order with booking',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Search Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: categories.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          backgroundColor: Colors.white,
                          label: Text(cat.name),
                          selected: cat == selectedCategory,
                          onSelected: (_) => setState(() => selectedCategory = cat),
                          selectedColor: Palette.newColorbg,
                          labelStyle: TextStyle(
                            color: cat == selectedCategory ? Palette.newColor : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  spacing: 10,
                  children: [
                    // Current Booking Card
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Current Booking',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Abraham John'),
                          Text('Badminton - Court 07'),
                          Text('10:00 AM - 11:30 AM'),
                        ],
                      ),
                    ),
                    // Upcoming Booking Card
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Upcoming Booking',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Abraham John'),
                          Text('Badminton - Court 07'),
                          Text('11:30 AM - 12:30 PM'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Buttons Row
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.white,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16),),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle Pay Now action
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 16),),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle Merge Order logic here
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.newColor,
                          minimumSize: const Size(150, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Merge Order', style: TextStyle(fontSize: 16, color: Colors.white),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkout() {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart before checkout!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Update order data before navigation
    final orderController = Get.find<PosOrderController>();
    orderController.updateOrder(_tempOrderId, cart, _orderNotes, total);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckoutScreen(
          type: 'Product',
          customerName: 'System Customer',
          mobileno: '+61 0000 000 000',
          selectedDateTime: DateTime.now(),
          billAmount: total,
          bookings: [],
          membershipID: '',
          membershipName: '',
          isMembershipApplied: false
      )),
    ).then((_) {
      // After returning from checkout
      _loadCartFromPrefs();
      _generateTempOrderId();
      setState(() {
        cart.clear();
        _orderNotes = '';
      });
      _saveCartToPrefs();
      _saveOrderNotesToPrefs();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          // Update from date
        } else {
          // Update to date
        }
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    Widget _buildNewOrderTab() {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Row(
            spacing: 15,
            children: [
              // Left Side - Product Area
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              backgroundColor: Colors.white,
                              label: Text(cat.name),
                              selected: cat == selectedCategory,
                              onSelected: (_) => setState(() => selectedCategory = cat),
                              selectedColor: Palette.newColorbg,
                              labelStyle: TextStyle(
                                color: cat == selectedCategory ? Palette.newColor : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 35,),
                            hintText: 'e.g Young Shuttlecock',
                            filled: true,
                            fillColor: Colors.white,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product Grid
                      Expanded(
                        child: filteredProducts.isEmpty
                            ? const Center(child: Text('No products found'))
                            : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredProducts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (_, index) {
                            final product = filteredProducts[index];
                            return InkWell(
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
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '\$${product.price}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Side - Cart
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey.shade300)),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                            'Order ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      // Cart Items with Swipe to Delete
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (_, index) {
                            final item = cart[index];
                            return Dismissible(
                              key: ValueKey(item.product.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => setState(() {
                                cart.remove(item);
                                _saveCartToPrefs();
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    // Product Name
                                    Expanded(
                                      child: Text(
                                          item.product.name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold
                                          ),
                                          overflow: TextOverflow.ellipsis
                                      ),
                                    ),
                                    // Quantity with Border
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => decrementQty(item),
                                            icon: const Icon(Icons.remove, size: 18),
                                          ),
                                          Text('${item.quantity}', style: const TextStyle(fontSize: 18)),
                                          IconButton(
                                            onPressed: () => incrementQty(item),
                                            icon: const Icon(Icons.add, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        '\$${(double.parse(item.product.price) * item.quantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Notes + Clear All
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showOrderNotesDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                minimumSize: const Size(100, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                spacing: 10,
                                children: [
                                  Icon(Icons.edit, size: 20,color: Colors.grey,),
                                  Text('Add Notes',style: TextStyle(color: Colors.grey, fontSize: 18))
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  cart.clear();
                                  _saveCartToPrefs();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                minimumSize: const Size(100, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                  'Clear All',
                                  style: TextStyle(color: Colors.grey, fontSize: 18)
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider( color: Colors.grey, thickness: 1,),
                      // Total
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                                'Total',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                            Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                                'GST Incl.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)
                            ),
                            Text(
                                '\$${(0.1 * total).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.white,
                                  minimumSize: const Size(150, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey, fontSize: 18)
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: cart.isEmpty ? null : _checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.newColor,
                                  minimumSize: const Size(150, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                    'Check Out',
                                    style: TextStyle(color: Colors.white, fontSize: 18)
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: cart.isEmpty ? null : () => _showMergeDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.newColorbg,
                                  minimumSize: const Size(150, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(Icons.call_merge, color: Palette.newColor, size: 35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildAllOrdersTab() {
      return Obx(() {

        if (ordersListController.isLoading && ordersListController.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ordersListController.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ordersListController.error),
                ElevatedButton(
                  onPressed: ordersListController.refreshOrders,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title on left, Search + Filter on right
              Row(
                spacing: 400,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Orders',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View all current and past orders in one place.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  // Right Search + Filter
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'e.g John',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            // filter logic
                          },
                          icon: Icon(Icons.filter_list, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Table Full Width
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black),
                      headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('Order Id')),
                        DataColumn(label: Text('Name & Mobile No.')),
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('Items')),
                        DataColumn(label: Text('Amount (\$)')),
                        DataColumn(label: Text('Order Status')),
                      ],
                      rows: ordersListController.orders.map((order) {
                        return DataRow(
                          onSelectChanged: (_) {
                            // Add navigation to order details if needed
                          },
                          cells: [
                            DataCell(Text('#${order.tokenNumber}')),
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                //Text(order.mobileNo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            )),
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${order.createdAt?.day} ${_getMonthName(order.createdAt!.month)} ${order.createdAt?.year}'),
                                Text('${order.createdAt?.hour}:${order.createdAt?.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            )),
                            DataCell(Text(
                              order.cartItems!.map((item) => item.product.name).join('/n '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Text('\$${order.billDetails?.billAmount!.toStringAsFixed(2)}')),
                            DataCell(
                              DropdownButton<String>(
                                value: order.orderStatus,
                                items: ['Pending', 'Paid', 'Cancelled', 'Completed']
                                    .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'Paid'
                                          ? Colors.green
                                          : status == 'Cancelled'
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                  ),
                                ))
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    //ordersController.updateOrderStatus(order.id, newStatus);
                                  }
                                },
                                underline: Container(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },);
    }



    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 20, right: 20, top: 20),
            width: MediaQuery.of(context).size.width / 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              //isScrollable: true,
              indicator: BoxDecoration(
                color: Colors.indigo.shade500,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorPadding: EdgeInsets.all(4),
              // labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade50,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),

              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'New Order'),
                Tab(text: 'All Orders'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // New Order Tab - Your existing content
                _buildNewOrderTab(),
                // All Orders Tab - New content
                _buildAllOrdersTab(),
              ],
            ),
          )
        ],
      ),
    );
  }
}