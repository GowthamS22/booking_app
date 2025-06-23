// widgets/cart_items.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:booking_app/controllers/cart_controller.dart';

class CartItems extends StatelessWidget {
  const CartItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: cartController.cartItems.length,
              itemBuilder: (_, index) {
                final item = cartController.cartItems[index];
                return Dismissible(
                  key: ValueKey(item.product.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text('Delete', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  onDismissed: (_) => cartController.removeItem(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              item.product.name,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold
                              ),
                              overflow: TextOverflow.ellipsis
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 14,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => cartController.decrementQty(item),
                                icon: const Icon(Icons.remove, size: 25),
                              ),
                              Obx(() => Text('${item.quantity.value}', style: const TextStyle(fontSize: 25))),
                              IconButton(
                                onPressed: () => cartController.incrementQty(item),
                                icon: const Icon(Icons.add, size: 25),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 110,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Obx(() => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '\$${item.appliedPrice.value.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25
                                  ),
                                ),
                              ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )),
          ),
          Obx(() => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: \$${cartController.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
    );
  }
}