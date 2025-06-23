// lib/widgets/addon_items_widget.dart
import 'dart:convert';
import 'dart:math';
import 'package:booking_app/config/palette.dart';
import 'package:booking_app/controllers/cart_controller.dart';
import 'package:booking_app/models/category.dart';
import 'package:booking_app/models/products.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddonItemsWidget extends StatefulWidget {
  const AddonItemsWidget({Key? key}) : super(key: key);

  @override
  State<AddonItemsWidget> createState() => _AddonItemsWidgetState();
}

class _AddonItemsWidgetState extends State<AddonItemsWidget> {
  static const String _prefsOrderNotesKey = 'order_notes';
  static const String _prefsOrderIdKey = 'order_id';

  List<Category> categories = [];
  List<Products> products = [];
  Category? selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isLoading = true;
  String _orderNotes = '';
  String _tempOrderId = '';

  final CartController cartController = Get.find<CartController>();

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
    _loadData().then((_) async {
      await _loadOrderIdFromPrefs();
      await _loadOrderNotesFromPrefs();
      setState(() => isLoading = false);
    });
    _searchController.addListener(_onSearchChanged);
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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _showProductsListDialog(BuildContext context) {
    final dialogSearchController = TextEditingController();
    String dialogSearchQuery = '';
    Category? dialogSelectedCategory = selectedCategory;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Products> getDialogFilteredProducts() {
              List<Products> filtered = dialogSelectedCategory == null
                  ? products
                  : products.where((p) => p.categoryId == dialogSelectedCategory!.id).toList();

              if (dialogSearchQuery.isNotEmpty) {
                filtered = filtered.where((p) =>
                p.name.toLowerCase().contains(dialogSearchQuery.toLowerCase()) ||
                    (p.description?.toLowerCase().contains(dialogSearchQuery.toLowerCase()) ?? false))
                    .toList();
              }

              return filtered;
            }

            return Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.58,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: categories.map((cat) => Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: ChoiceChip(
                                  backgroundColor: Colors.white,
                                  label: Text(cat.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal)),
                                  selected: cat == dialogSelectedCategory,
                                  onSelected: (_) => setState(() {
                                    dialogSelectedCategory = cat;
                                    selectedCategory = cat;
                                  }),
                                  selectedColor: Palette.newColorbg,
                                  labelStyle: TextStyle(
                                    color: cat == dialogSelectedCategory ? Palette.newColor : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: Colors.grey.shade300, width: 2)
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          //   child: TextField(
                          //     controller: dialogSearchController,
                          //     onChanged: (value) {
                          //       setState(() {
                          //         dialogSearchQuery = value;
                          //       });
                          //     },
                          //     style: TextStyle(fontSize: 25),
                          //     decoration: InputDecoration(
                          //       prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 35),
                          //       hintText: 'e.g Young Shuttlecock',
                          //       hintStyle: TextStyle(fontSize: 25),
                          //       filled: true,
                          //       fillColor: Colors.white,
                          //       border: UnderlineInputBorder(
                          //         borderSide: BorderSide(
                          //           color: Colors.grey.shade300,
                          //           width: 1.0,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          Expanded(
                            child: getDialogFilteredProducts().isEmpty
                                ? const Center(child: Text('No products found'))
                                : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: getDialogFilteredProducts().length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemBuilder: (_, index) {
                                final product = getDialogFilteredProducts()[index];
                                return InkWell(
                                  onTap: () {
                                    cartController.addToCart(product);
                                    //Navigator.of(context).pop();
                                  },
                                  child: Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Image.network(
                                            product.imageUrl.toString(),
                                            errorBuilder: (context, error, stackTrace) => Image.network(
                                              'https://placehold.co/150x100/png',
                                              fit: BoxFit.cover,
                                            ),
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
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    dialogSearchController.dispose();
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
              const Text("Need Accessories?", style: TextStyle(fontSize: 22)),
              ElevatedButton(
                onPressed: () => _showProductsListDialog(context),
                child: const Text("View More", style: TextStyle(fontSize: 22, color: Colors.black54)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    onTap: () => cartController.addToCart(product),
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