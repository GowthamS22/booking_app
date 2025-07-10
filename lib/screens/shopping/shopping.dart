import 'dart:convert';
import 'dart:math';
import 'package:booking_app/controllers/PosOrderController.dart';
import 'package:booking_app/controllers/checkout_controller.dart';
import 'package:booking_app/controllers/orders_list_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:booking_app/stores/order_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booking_app/config/palette.dart';
import 'package:booking_app/models/category.dart';
import 'package:booking_app/models/products.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  final OrdersListController ordersListController = Get.put(
    OrdersListController(),
  );
  final CheckoutController checkoutController = Get.put(CheckoutController());

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
        categories =
            categoryData.map((json) => Category.fromJson(json)).toList();
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
    List<Products> filtered =
        selectedCategory == null
            ? products
            : products
                .where((p) => p.categoryId == selectedCategory!.id)
                .toList();

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.description.toLowerCase().contains(_searchQuery),
              )
              .toList();
    }

    return filtered;
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

  void incrementQty(CartItem item) {
    setState(() {
      item.quantity++;
      item.updateAppliedPrice();
      _saveCartToPrefs();
    });
  }

  void decrementQty(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
        item.updateAppliedPrice();
      } else {
        cart.remove(item);
      }
      _saveCartToPrefs();
    });
  }

  double get total => cart.fold(
    0,
    (sum, item) => sum + double.parse(item.product.price) * item.quantity,
  );

  Future<void> _showOrderNotesDialog(BuildContext context) async {
    final TextEditingController notesController = TextEditingController(
      text: _orderNotes,
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.white,
            title: const Text('Order Notes', style: TextStyle(fontSize: 25)),
            content: Container(
              width: 600,
              child: TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Special instructions for the entire order...',
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(fontSize: 22),
                ),
                style: TextStyle(fontSize: 22),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 25)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _orderNotes = notesController.text;
                    _saveOrderNotesToPrefs();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save', style: TextStyle(fontSize: 25)),
              ),
            ],
          ),
    );
  }

  void _showMergeDialog(BuildContext context) async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart before merging!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final ordersController = Get.find<OrdersListController>();
    ordersController.currentBookings.clear();
    ordersController.upcomingBookings.clear();
    ordersController.selectedCurrentBooking.value = null;
    ordersController.selectedUpcomingBooking.value = null;

    final prefs = await SharedPreferences.getInstance();
    final sportsWithPlatforms = prefs.getString('sportsWithPlatforms');
    final List<dynamic> sportsWithPlatformData = jsonDecode(
      sportsWithPlatforms!,
    );

    // Convert to typed list
    final List<Map<String, dynamic>> sports =
        sportsWithPlatformData.cast<Map<String, dynamic>>();

    // Track selected sport and platform
    Map<String, dynamic>? selectedSport;
    Map<String, dynamic>? selectedPlatform;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Merge purchase order with booking',
                          style: TextStyle(color: Colors.grey, fontSize: 22),
                        ),
                        const SizedBox(height: 12),

                        // Sports Selection
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                sports.map((sport) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ChoiceChip(
                                      labelPadding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      backgroundColor: Colors.white,
                                      label: Text(
                                        sport['sport_name'] ?? 'Unknown Sport',
                                        style: TextStyle(fontSize: 25),
                                      ),
                                      selected: selectedSport == sport,
                                      onSelected: (_) {
                                        setState(() {
                                          selectedSport = sport;
                                          selectedPlatform = null;
                                        });
                                        if (selectedPlatform != null) {
                                          ordersController
                                              .fetchBookingsForCourt(
                                                courtId:
                                                    selectedPlatform!['id'],
                                                currentTime: DateTime.now(),
                                              );
                                        }
                                      },
                                      selectedColor: Palette.newColorbg,
                                      labelStyle: TextStyle(
                                        color:
                                            selectedSport == sport
                                                ? Palette.newColor
                                                : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Search Bar
                        // Platforms Selection (only shown when a sport is selected)
                        if (selectedSport != null &&
                            selectedSport!['platform_status'] != null)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  (selectedSport!['platform_status'] as List).map((
                                    platform,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: ChoiceChip(
                                        labelPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        backgroundColor: Colors.white,
                                        label: Text(
                                          '${selectedSport!['platform_name']} ${platform['platform_id']}',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                        selected: selectedPlatform == platform,
                                        onSelected: (_) {
                                          setState(
                                            () => selectedPlatform = platform,
                                          );
                                          ordersController
                                              .fetchBookingsForCourt(
                                                courtId: platform['id'],
                                                currentTime: DateTime.now(),
                                              );
                                        },
                                        selectedColor: Colors.blue[100],
                                        labelStyle: TextStyle(
                                          color:
                                              selectedPlatform == platform
                                                  ? Colors.blue
                                                  : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 30,
                          children: [
                            // Current Booking Card
                            Obx(() {
                              if (ordersController.isBookingLoading.value) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (ordersController.currentBookings.isEmpty) {
                                return Container(
                                  height: 200,
                                  width: 300,
                                  alignment: AlignmentDirectional.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Text(
                                    'No current booking',
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  final booking =
                                      ordersController.currentBookings.first;
                                  ordersController.selectCurrentBooking(
                                    booking,
                                  );
                                },
                                child: Container(
                                  height: 200,
                                  width: 300,
                                  alignment: AlignmentDirectional.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          ordersController
                                                      .selectedCurrentBooking
                                                      .value !=
                                                  null
                                              ? Colors.blue
                                              : Colors.green,
                                      width:
                                          ordersController
                                                      .selectedCurrentBooking
                                                      .value !=
                                                  null
                                              ? 3
                                              : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Booking',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...ordersController.currentBookings.map((
                                        booking,
                                      ) {
                                        final slot = booking.slots.first;
                                        final customer = booking.customer;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (customer != null) ...[
                                              Text(
                                                '${customer.fullName.toUpperCase()}',
                                                style: TextStyle(fontSize: 22),
                                              ),
                                            ],
                                            Text(
                                              '${selectedSport?['platform_name']} - ${selectedPlatform?['platform_id']}',
                                              style: TextStyle(fontSize: 22),
                                            ),
                                            Text(
                                              '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                                              style: TextStyle(fontSize: 22),
                                            ),
                                            if (ordersController
                                                    .selectedCurrentBooking
                                                    .value !=
                                                null)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 30,
                                              ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // Upcoming Booking Card
                            Obx(() {
                              if (ordersController.isBookingLoading.value) {
                                return const SizedBox.shrink();
                              }

                              if (ordersController.upcomingBookings.isEmpty) {
                                return Container(
                                  height: 200,
                                  width: 300,
                                  alignment: AlignmentDirectional.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Text(
                                    'No Upcoming booking',
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  final booking =
                                      ordersController.upcomingBookings.first;
                                  ordersController.selectUpcomingBooking(
                                    booking,
                                  );
                                },
                                child: Container(
                                  height: 200,
                                  width: 300,
                                  alignment: AlignmentDirectional.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          ordersController
                                                      .selectedUpcomingBooking
                                                      .value !=
                                                  null
                                              ? Colors.blue
                                              : Colors.orange,
                                      width:
                                          ordersController
                                                      .selectedUpcomingBooking
                                                      .value !=
                                                  null
                                              ? 3
                                              : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Upcoming Booking',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 25,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...ordersController.upcomingBookings.map((
                                        booking,
                                      ) {
                                        final slot = booking.slots.first;
                                        final customer = booking.customer;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (customer != null) ...[
                                              Text(
                                                '${customer.fullName.toUpperCase()}',
                                                style: TextStyle(fontSize: 22),
                                              ),
                                            ],
                                            Text(
                                              '${selectedSport?['platform_name']} - ${selectedPlatform?['platform_id']}',
                                              style: TextStyle(fontSize: 22),
                                            ),
                                            Text(
                                              '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}',
                                              style: TextStyle(fontSize: 22),
                                            ),
                                            if (ordersController
                                                    .selectedUpcomingBooking
                                                    .value !=
                                                null)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 30,
                                              ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Buttons Row
                        Row(
                          spacing: 10,
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
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                            // Expanded(
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            //       final selectedBooking = ordersController.selectedBooking;
                            //       if (selectedBooking == null) {
                            //         showCustomSnackbar('Warning', 'Please select a booking first!', Colors.orange);
                            //         return;
                            //       }
                            //
                            //       Navigator.pop(context);
                            //       _checkout();
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.green,
                            //       minimumSize: const Size(150, 50),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(10),
                            //       ),
                            //     ),
                            //     child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontSize: 25),),
                            //   ),
                            // ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {

                                  final selectedBooking = ordersController.selectedBooking;
                                  if (selectedBooking == null) {
                                    showCustomSnackbar(
                                      'Warning',
                                      'Please select a booking first!',
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  await checkoutController.createTempOrder(total: total).then((value) async {
                                     final orderId = value['id'];
                                     await checkoutController.mergeBookingtoOrder(
                                        booking_id: selectedBooking.id,
                                        customer_id: selectedBooking.customer?.id,
                                        order_id: orderId,
                                     );

                                     // Clear cart and refresh after successful merge
                                     setState(() {
                                       cart.clear();
                                       _orderNotes = '';
                                     });
                                     await _saveCartToPrefs();
                                     await _saveOrderNotesToPrefs();
                                     _generateTempOrderId();

                                     // Close the dialog
                                     Navigator.pop(context);

                                  });

                                  //Navigator.pop(context);
                                  //Get.offAllNamed('/');
                                  // Add your merge order logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.newColor,
                                  minimumSize: const Size(150, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Merge Order',
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

    String userId = '';
    TextEditingController nameController = TextEditingController();
    TextEditingController mobileController = TextEditingController();

    void _updateUserData(Map<String, dynamic> userData) {
      nameController.text = userData['name'];
      mobileController.text = userData['mobile'];
      userId = userData['id'];
    }

    Future<void> _validateAndFetchUserData(String mobile) async {
      if (mobile.length == 12) {
        final suggestions = await ordersListController.fetchUserSuggestions(mobile);
        if (suggestions.isNotEmpty) {
          final exactMatch = suggestions.firstWhere((user) => user['mobile'] == mobile,orElse: () => {},);
          if (exactMatch.isNotEmpty) {
            _updateUserData(exactMatch);
          } else {
            userId = '';
          }
        } else {
          userId = '';
        }
      } else {
        userId = '';
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please enter the customer details',
                      style: TextStyle(color: Colors.grey, fontSize: 22),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 30,
                      children: [

                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      color: Colors.grey.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 200,
                                  maxWidth:
                                  MediaQuery.of(
                                    context,
                                  ).size.width *
                                      0.50,
                                ),
                                child: TypeAheadField<
                                    Map<String, dynamic>
                                >(
                                  controller: nameController,
                                  suggestionsCallback: (pattern) async {
                                    return await ordersListController.fetchUserSuggestions(pattern);
                                  },
                                  builder: (context, _, focusNode) {
                                    return TextFormField(
                                      controller: nameController,
                                      focusNode: focusNode,
                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Name is required';
                                        }
                                        return null;
                                      },
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                          vertical: 15,
                                          horizontal: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  itemBuilder: (context, suggestion) {
                                    return ListTile(
                                      title: Text(
                                        suggestion['name'],
                                        style: TextStyle(fontSize: 22),
                                      ),
                                      subtitle: Text(
                                        suggestion['mobile'],
                                        style: TextStyle(fontSize: 22),
                                      ),
                                    );
                                  },
                                  onSelected: (suggestion) {
                                    setState(() {
                                      mobileController.text = suggestion['mobile'];
                                      nameController.text = suggestion['name'];
                                      userId = suggestion['id'];
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mobile',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 200,
                                  maxWidth: MediaQuery.of(context).size.width * 0.50,
                                ),
                                child: Autocomplete<Map<String, dynamic>>(
                                  displayStringForOption: (option) => option['mobile'] ?? '',
                                  optionsBuilder: (TextEditingValue textEditingValue) async {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<Map<String, dynamic>>.empty();
                                    }
                                    return await ordersListController.fetchUserSuggestions(textEditingValue.text);
                                  },
                                  onSelected: (Map<String, dynamic> selection) {
                                    _updateUserData(selection);
                                    // Hide keyboard after selection
                                    FocusScope.of(context).unfocus();
                                  },
                                  fieldViewBuilder: (BuildContext context,
                                      TextEditingController fieldTextEditingController,
                                      FocusNode fieldFocusNode,
                                      VoidCallback onFieldSubmitted) {

                                    if (mobileController.text != fieldTextEditingController.text) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        fieldTextEditingController.text = mobileController.text;
                                      });
                                    }

                                    return TextFormField(
                                      controller: fieldTextEditingController,
                                      focusNode: fieldFocusNode,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.done, // Changed to 'done' for better UX
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        MobileNumberFormatter(),
                                      ],
                                      onChanged: (value) {
                                        mobileController.text = value;
                                        _validateAndFetchUserData(mobileController.text);
                                      },
                                      onFieldSubmitted: (value) {
                                        _validateAndFetchUserData(value);
                                        FocusScope.of(context).unfocus();
                                      },
                                      onEditingComplete: () {
                                        final digitsOnly = mobileController.text.replaceAll(RegExp(r'\D'), '');
                                        if (digitsOnly.length == 10) {
                                          _validateAndFetchUserData(mobileController.text);
                                        }
                                        FocusScope.of(context).unfocus();
                                      },
                                      validator: (value) {
                                        final digitsOnly = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                                        if (digitsOnly.isEmpty) return 'Mobile number is required';
                                        if (digitsOnly.length != 10) return 'Enter a valid 10-digit number';
                                        return null;
                                      },
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  optionsViewBuilder: (BuildContext context,
                                      AutocompleteOnSelected<Map<String, dynamic>> onSelected,
                                      Iterable<Map<String, dynamic>> options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4.0,
                                        child: SizedBox(
                                          height: 200,
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: options.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              final Map<String, dynamic> option = options.elementAt(index);
                                              return ListTile(
                                                title: Text(
                                                  option['name'],
                                                  style: const TextStyle(fontSize: 22),
                                                ),
                                                subtitle: Text(
                                                  option['mobile'],
                                                  style: const TextStyle(fontSize: 22),
                                                ),
                                                onTap: () {
                                                  onSelected(option);
                                                  // Hide keyboard after tap
                                                  FocusScope.of(context).unfocus();
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 40),

                    // Buttons Row
                    Row(
                      spacing: 10,
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
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 25,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {

                              if(nameController.text.trim().isEmpty) {
                                showCustomSnackbar('Warning', 'Please enter the customer name', Colors.orangeAccent);
                                return;
                              }

                              final digitsOnly = mobileController.text.replaceAll(RegExp(r'\D'), '');
                              if (digitsOnly.isEmpty) {
                                showCustomSnackbar('Warning', 'Mobile number is required', Colors.orangeAccent);
                                return;
                              }

                              if (digitsOnly.length != 10) {
                                showCustomSnackbar('Warning', 'Enter a valid 10-digit mobile number', Colors.orangeAccent);
                                return;
                              }

                              // Update order data before navigation
                              final orderController = Get.find<PosOrderController>();
                              orderController.updateOrder(_tempOrderId, cart, _orderNotes, total);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CheckoutScreen(
                                    type: 'Product',
                                    customerName: nameController.text,
                                    mobileno: mobileController.text,
                                    selectedDateTime: DateTime.now(),
                                    billAmount: total,
                                    bookings: [],
                                    membershipID: '',
                                    membershipName: '',
                                    isMembershipApplied: false,
                                    membershipPrice: 0.0,
                                    forpayment: 'product-only',
                                    exuserId: userId,
                                  ),
                                ),
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
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.newColor,
                              minimumSize: const Size(150, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Proceed',
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      )
    );

    return;
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                flex: 4,
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
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children:
                              categories
                                  .map(
                                    (cat) => Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: ChoiceChip(
                                        backgroundColor: Colors.white,
                                        label: Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        selected: cat == selectedCategory,
                                        onSelected:
                                            (_) => setState(
                                              () => selectedCategory = cat,
                                            ),
                                        selectedColor: Palette.newColorbg,
                                        labelStyle: TextStyle(
                                          color:
                                              cat == selectedCategory
                                                  ? Palette.newColor
                                                  : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 25),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 35,
                            ),
                            hintText: 'e.g Young Shuttlecock',
                            hintStyle: TextStyle(fontSize: 25),
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
                      // Product Grid
                      Expanded(
                        child:
                            filteredProducts.isEmpty
                                ? const Center(child: Text('No products found'))
                                : GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredProducts.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                      ),
                                  itemBuilder: (_, index) {
                                    final product = filteredProducts[index];
                                    return InkWell(
                                      onTap: () => addToCart(product),
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Image.network(
                                              product.imageUrl.toString(),
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Image.network(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              child: Text(
                                                '\$${product.price}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 25,
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
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          'Order #$_tempOrderId',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onDismissed:
                                  (_) => setState(() {
                                    cart.remove(item);
                                    _saveCartToPrefs();
                                  }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Row(
                                  spacing: 20,
                                  children: [
                                    // Product Name
                                    Expanded(
                                      child: Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Quantity with Border
                                    Container(
                                      width:
                                          MediaQuery.of(context).size.width /
                                          14,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () => decrementQty(item),
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 25,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 25,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => incrementQty(item),
                                            icon: const Icon(
                                              Icons.add,
                                              size: 25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price
                                    Container(
                                      width: 110,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              '\$${(double.parse(item.product.price) * item.quantity).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 25,
                                              ),
                                            ),
                                          ),
                                        ],
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
                        padding: const EdgeInsets.only(top: 15, bottom: 5),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showOrderNotesDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                minimumSize: const Size(100, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                spacing: 10,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    'Add Notes',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 25,
                                    ),
                                  ),
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
                                minimumSize: const Size(100, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      // Total
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GST Incl.',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              '\$${(total * 0.1 / 1.1).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.white,
                                  minimumSize: const Size(150, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: cart.isEmpty ? null : _checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.newColor,
                                  minimumSize: const Size(150, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Check Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    cart.isEmpty
                                        ? null
                                        : () => _showMergeDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.newColorbg,
                                  minimumSize: const Size(150, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.call_merge,
                                  color: Palette.newColor,
                                  size: 45,
                                ),
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

    Future<String?> _getCenterSlug() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('centerSlug');
    }

    String _getMonthName(int month) {
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return months[month - 1];
    }

    String _formatDate(String? dateStr) {
      if (dateStr == null) return '-';
      final dateTime = DateTime.tryParse(dateStr);
      if (dateTime == null) return '-';
      return "${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}";
    }

    String _formatTime(String? dateStr) {
      if (dateStr == null) return '-';
      final dateTime = DateTime.tryParse(dateStr);
      if (dateTime == null) return '-';
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    Widget _buildHeader() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 400,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Orders', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('View all current and past orders in one place.', style: TextStyle(color: Colors.grey[600], fontSize: 25)),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'e.g John',
                  hintStyle: const TextStyle(fontSize: 22),
                  prefixIcon: const Icon(Icons.search, size: 35,),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 22),
                onChanged: (value) {
                  // Optional: Add filtering logic
                },
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildCartItems(List<dynamic>? items) {
      if (items == null || items.isEmpty) {
        return Text("No items", style: TextStyle(fontSize: 22));
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.map((item) {
            // Handle both Map and String formats
            final product = item is Map ? item['product'] : jsonDecode(item)['product'];
            final quantity = item is Map ? item['quantity'] : jsonDecode(item)['quantity'];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '${product['name']} (x$quantity) - \$${(double.parse(product['price'].toString()) * quantity)}',
                style: TextStyle(fontSize: 22),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget _buildAllOrdersTab() {
      return FutureBuilder<String?>(
        future: _getCenterSlug(), // Fetch centerSlug first
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final centerSlug = snapshot.data!;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .schema('${centerSlug}_prod_schema')
                .from('orders')
                .stream(primaryKey: ['id'])
                .eq('closed', false)
                .order('created_at', ascending: false)
                .map((data) => data as List<Map<String, dynamic>>),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = (snapshot.data ?? []).where((order) {
                final token = order['token_number'];
                return token != null && !(token.toString().startsWith('TMP'));
              }).toList();

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
                    _buildHeader(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 24,
                            dataRowMinHeight: 60, // Reduced from 80
                            dataRowMaxHeight: double.infinity, // Allow rows to expand as needed
                            headingRowHeight: 70,
                            headingRowColor: MaterialStateProperty.all(Colors.black),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                            columns: const [
                              DataColumn(label: Text('Order Id')),
                              DataColumn(label: Text('Name & Mobile No.')),
                              DataColumn(label: Text('Date & Time')),
                              DataColumn(label: Text('Items')),
                              DataColumn(label: Text('Amount (\$)')),
                              DataColumn(label: Text('Order Status')),
                            ],
                            rows: orders.map((order) {
                              final cartItems = order['cart_items'] ?? order['items'];
                              final itemCount = cartItems is List ? cartItems.length : 1;
                              final rowHeight = 60.0 + (itemCount * 30.0); // Base height + additional for each item

                              return DataRow(
                                cells: [
                                  DataCell(Text('#${order['token_number'] ?? ''}', style: const TextStyle(fontSize: 22))),
                                  DataCell(
                                    order['customer_id'] == null
                                        ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text('Guest', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                        Text('-', style: TextStyle(fontSize: 22, color: Colors.grey)),
                                      ],
                                    )
                                        : FutureBuilder(
                                      future: Supabase.instance.client
                                          .schema('${centerSlug}_prod_schema')
                                          .from('customers')
                                          .select()
                                          .eq('id', order['customer_id'])
                                          .maybeSingle(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox(
                                            width: 100,
                                            height: 40,
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        }

                                        if (snapshot.hasError || snapshot.data == null) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text('Unknown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                              Text('-', style: TextStyle(fontSize: 22, color: Colors.grey)),
                                            ],
                                          );
                                        }

                                        final customer = snapshot.data as Map<String, dynamic>;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(customer['first_name'] ?? 'No Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                                            Text(customer['mobile'] ?? '-', style: TextStyle(fontSize: 22, color: Colors.grey[600])),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(Row(
                                    spacing: 10,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatDate(order['created_at']), style: const TextStyle(fontSize: 22)),
                                      Text(_formatTime(order['created_at']), style: TextStyle(fontSize: 22, color: Colors.grey[600])),
                                    ],
                                  )),
                                  DataCell(_buildCartItems(cartItems)),
                                  DataCell(Text('\$${order['bill_details']?['billAmount']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 22))),
                                  DataCell(Text(order['order_status'] ?? '-', style: const TextStyle(fontSize: 22))),
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
            },
          );
        },
      );
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
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              height: 70,
              child: TabBar(
                controller: _tabController,
                //isScrollable: true,
                indicator: BoxDecoration(
                  color: Colors.indigo.shade500,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorPadding: EdgeInsets.all(4),
                // labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade50,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [Tab(text: 'New Order'), Tab(text: 'All Orders')],
              ),
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
          ),
        ],
      ),
    );
  }
}

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    final limited = digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;

    // Apply formatting: XXXX XXX XXX
    String formatted = '';
    for (int i = 0; i < limited.length; i++) {
      if (i == 4 || i == 7) {
        formatted += ' ';
      }
      formatted += limited[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}