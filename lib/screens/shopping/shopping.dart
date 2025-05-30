import 'package:booking_app/controllers/shopping_controller.dart';
import 'package:booking_app/screens/checkout/checkout_screen.dart';
import 'package:booking_app/screens/shopping/products.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../app/getx_binding.dart';
import '../../config/constants.dart';
import '../../config/google-fonts.dart';
import '../../config/palette.dart';
import '../../widgets/shimmer/shimmer_table_loading.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  @override
  void initState() {
    super.initState();
    print('Shopping Scrren : ${shoppingController.categoryList.length}');
    shoppingController.categoryList.length;
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    return GetBuilder<ShoppingController>(
      builder: (controller) {
        //shoppingController.tabController.index = 0;
        return Scaffold(
          backgroundColor: Palette.white,
          body: Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [buildBody(controller, searchController)],
              ),
            ),
          ),
        );
      },
    );
  }

  buildBody(
    ShoppingController controller,
    TextEditingController searchController,
  ) {
    String dropdownValue = shoppingController.list.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 21 * fem),
          width: double.infinity,
          height: 44 * fem,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  // width: MediaQuery.of(context).size.width / 2,
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    175.4 * fem,
                    0 * fem,
                  ),
                  height: double.infinity,
                  child: Obx(() {
                    final categories = controller.categoryList;

                    if (categories.isEmpty) {
                      return Center(child: Text("No categories available."));
                    }
                    return TabBar(
                      controller: controller.tabController,
                      isScrollable: true,
                      labelColor: Palette.tabBarSelectedColor,
                      unselectedLabelColor: Palette.tabBarUnselectedColor,
                      unselectedLabelStyle: SafeGoogleFont(
                        'Roboto',
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff2c83f1),
                      ),
                      labelStyle: SafeGoogleFont(
                        'Roboto',
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff2c83f1),
                      ),
                      tabs: List.generate(
                        controller.categoryList.length,
                        (index) => Tab(
                          height: 70,
                          child: Text('${controller.categoryList[index].name}'),
                        ),
                      ),
                    );
                  }),
                ),
                // SizedBox(width: 100,),
                Container(
                  // datefilternkq (137:817)
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0.46 * fem,
                    0 * fem,
                    0.46 * fem,
                  ),
                  height: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        // frame454vs3 (137:818)
                        margin: EdgeInsets.fromLTRB(
                          0 * fem,
                          1.54 * fem,
                          22.76 * fem,
                          1.54 * fem,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          8.13 * fem,
                          10.25 * fem,
                          8.13 * fem,
                          10.25 * fem,
                        ),
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xffdfe7f4),
                          borderRadius: BorderRadius.circular(
                            4.0638589859 * fem,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              // height: 20,
                              width: 180,
                              // color: Colors.red,
                              // searchczm (137:819)
                              margin: EdgeInsets.fromLTRB(
                                0 * fem,
                                1 * fem,
                                70 * fem,
                                0 * fem,
                              ),
                              // child: Text(
                              //   'Search',
                              //   style: SafeGoogleFont (
                              //     'Roboto',
                              //     fontSize: 14.6298923492*ffem,
                              //     fontWeight: FontWeight.w400,
                              //     height: 1.1725*ffem/fem,
                              //     color: Color(0xff637185),
                              //   ),
                              // ),
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  // controller.searchCategory(value);
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(top: 10),
                                  isDense: true,
                                  hintText: "Search",
                                  hintStyle: TextStyle(
                                    fontSize: 14.6298923492 * ffem,
                                  ),
                                  // suffixIcon: Icon(Icons.search_outlined, color: Palette.mediumGrey,size: 40,),
                                ),
                              ),
                            ),
                            Container(
                              // mysteryLA5 (137:820)
                              width: 19.51 * fem,
                              height: 19.51 * fem,
                              // color: Colors.green,
                              child: Image.asset(
                                'assets/images/icons/mystery-aVo.png',
                                width: 19.51 * fem,
                                height: 19.51 * fem,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        // value: dropdownValue,
                        // hint:,
                        icon: Container(
                          // frame482fTF (137:823)
                          width: 43.08 * fem,
                          height: 43.08 * fem,
                          child: Image.asset(
                            'assets/images/icons/frame-482.png',
                            width: 43.08 * fem,
                            height: 43.08 * fem,
                          ),
                        ),
                        elevation: 16,
                        style: const TextStyle(color: Palette.primaryColor),
                        underline: SizedBox.shrink(),
                        onChanged: (String? value) {
                          // This is called when the user selects an item.
                          setState(() {
                            dropdownValue = value!;

                            switch (value) {
                              case 'H to L':
                                controller.productsList.sort(
                                  (a, b) => b.price!.compareTo(a.price!),
                                );
                              case 'L to H':
                                controller.productsList.sort(
                                  (a, b) => a.price!.compareTo(b.price!),
                                );
                              case 'A to Z':
                                controller.productsList.sort(
                                  (a, b) => a.name!.compareTo(b.name!),
                                );
                              case 'Z to A':
                                controller.productsList.sort(
                                  (a, b) => b.name!.compareTo(a.name!),
                                );
                            }
                          });
                        },
                        items:
                            shoppingController.list
                                .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                })
                                .toList(),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   color: Palette.fieldBg,
                //   height: 70,
                //   child: Padding(
                //     padding: const EdgeInsets.all(15.0),
                //     child: TextField(
                //       controller: searchController,
                //       onChanged: (value) {
                //         //controller.searchCategory(value);
                //       },
                //       decoration: const InputDecoration(
                //         border: InputBorder.none,
                //         contentPadding: EdgeInsets.all(10),
                //         isDense: true,
                //         hintText: "Search",
                //         hintStyle: TextStyle(fontSize: 25),
                //         // suffixIcon: Icon(Icons.search_outlined, color: Palette.mediumGrey,size: 40,),
                //       ),
                //     ),
                //   ),
                // )
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                // width: 200,
                // color: Colors.red,
                height: Get.height / 1.59,
                child:
                    controller.tabController == null ||
                            controller.categoryList.isEmpty
                        ? const SizedBox()
                        : Obx(() {
                          if (controller.productsList.isNotEmpty) {
                            return TabBarView(
                              controller: controller.tabController,
                              children: List.generate(
                                controller.categoryList.length,
                                (index) => ProductScreen(),
                              ),
                            );
                          } else if (controller.showNoItemsFound.value ==
                              true) {
                            return Center(child: Text('No Products Available'));
                          } else {
                            return ShimmerTableLoading(
                              columnCount: 2,
                              rowCount: 4,
                            );
                          }
                        }),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                // cartviewEjb (318:8031)
                padding: EdgeInsets.fromLTRB(
                  0 * fem,
                  0 * fem,
                  0 * fem,
                  10 * fem,
                ),
                width: 197 * fem,
                height: Get.height / 1.45,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xffd1d7e2)),
                  borderRadius: BorderRadius.circular(8 * fem),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        // toptitleXCu (318:8029)
                        padding: EdgeInsets.fromLTRB(
                          10 * fem,
                          10 * fem,
                          9 * fem,
                          10 * fem,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xffc0d1e8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 150,
                              // orderno667485pho (318:7974)
                              margin: EdgeInsets.fromLTRB(
                                0 * fem,
                                0 * fem,
                                30 * fem,
                                0 * fem,
                              ),
                              child: Text(
                                'Order No. #${controller.uuid.value.toString()}',
                                overflow: TextOverflow.ellipsis,
                                style: SafeGoogleFont(
                                  'Roboto',
                                  fontSize: 12 * ffem,
                                  fontWeight: FontWeight.w500,
                                  height: 2 * ffem / fem,
                                  letterSpacing: 0.3740000129 * fem,
                                  color: Color(0xff000000),
                                ),
                              ),
                            ),
                            // Text(
                            //   // johncole6fK (318:7975)
                            //   'John Cole',
                            //   style: SafeGoogleFont(
                            //     'Roboto',
                            //     fontSize: 11 * ffem,
                            //     fontWeight: FontWeight.w500,
                            //     height: 2 * ffem / fem,
                            //     letterSpacing: 0.3740000129 * fem,
                            //     color: Color(0xff000000),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      Container(
                        // productsecQR7 (318:8127)
                        // color: Colors.red,
                        width: double.infinity,
                        height: 318.96 * fem,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(() {
                              return shoppingController
                                      .productsCartModal
                                      .isNotEmpty
                                  ? Expanded(
                                    child: ListView.separated(
                                      separatorBuilder:
                                          (BuildContext context, int index) =>
                                              SizedBox(height: 5),
                                      itemCount:
                                          shoppingController
                                              .productsCartModal
                                              .length,
                                      itemBuilder: (
                                        BuildContext context,
                                        int index,
                                      ) {
                                        return Container(
                                          // ordercontanierL3s (318:7992)
                                          padding: EdgeInsets.fromLTRB(
                                            10 * fem,
                                            0 * fem,
                                            9 * fem,
                                            10 * fem,
                                          ),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color(0xffc4cdd8),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                // prodpriceRb7 (318:8093)
                                                margin: EdgeInsets.fromLTRB(
                                                  0 * fem,
                                                  0 * fem,
                                                  0 * fem,
                                                  8 * fem,
                                                ),
                                                width: double.infinity,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 100 * fem,
                                                      margin:
                                                          EdgeInsets.fromLTRB(
                                                            0 * fem,
                                                            0 * fem,
                                                            38 * fem,
                                                            0 * fem,
                                                          ),
                                                      child: Text(
                                                        '${shoppingController.productsCartModal[index].name}',
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: SafeGoogleFont(
                                                          'Roboto',
                                                          fontSize: 14 * ffem,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height:
                                                              1.7142857143 *
                                                              ffem /
                                                              fem,
                                                          letterSpacing:
                                                              0.3740000129 *
                                                              fem,
                                                          color: Color(
                                                            0xff000000,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Obx(() {
                                                      return Text(
                                                        '\$ ${shoppingController.productsCartModal[index].salePrice! * shoppingController.productsCartModal[index].count!.value}',
                                                        style: SafeGoogleFont(
                                                          'Roboto',
                                                          fontSize: 14 * ffem,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height:
                                                              1.7142857143 *
                                                              ffem /
                                                              fem,
                                                          letterSpacing:
                                                              0.3740000129 *
                                                              fem,
                                                          color: Color(
                                                            0xff000000,
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                // quantdelPAZ (318:8094)
                                                margin: EdgeInsets.fromLTRB(
                                                  0 * fem,
                                                  0 * fem,
                                                  1 * fem,
                                                  0 * fem,
                                                ),
                                                width: double.infinity,
                                                height: 36 * fem,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      // quantitygfT (318:7980)
                                                      margin:
                                                          EdgeInsets.fromLTRB(
                                                            0 * fem,
                                                            0 * fem,
                                                            34 * fem,
                                                            0 * fem,
                                                          ),
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                            5 * fem,
                                                            4 * fem,
                                                            5 * fem,
                                                            4 * fem,
                                                          ),
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: Color(
                                                            0xffd5d7da,
                                                          ),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              50 * fem,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              if (shoppingController
                                                                      .productsCartModal[index]
                                                                      .count!
                                                                      .value >
                                                                  1) {
                                                                shoppingController
                                                                    .productsCartModal[index]
                                                                    .count!
                                                                    .value--;
                                                              }
                                                            },
                                                            child: Container(
                                                              // frame681y8m (318:7981)
                                                              width: 28 * fem,
                                                              height:
                                                                  double
                                                                      .infinity,
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  0xff2c83f1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      50 * fem,
                                                                    ),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  '-',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: SafeGoogleFont(
                                                                    'Roboto',
                                                                    fontSize:
                                                                        16 *
                                                                        ffem,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    height:
                                                                        1.125 *
                                                                        ffem /
                                                                        fem,
                                                                    letterSpacing:
                                                                        0.3740000129 *
                                                                        fem,
                                                                    color: Color(
                                                                      0xffffffff,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: 9 * fem,
                                                          ),
                                                          Obx(() {
                                                            return Text(
                                                              shoppingController
                                                                          .productsCartModal[index]
                                                                          .count!
                                                                          .value >
                                                                      9
                                                                  ? '${shoppingController.productsCartModal[index].count!.value}'
                                                                  : '0${shoppingController.productsCartModal[index].count!.value}',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: SafeGoogleFont(
                                                                'Roboto',
                                                                fontSize:
                                                                    12 * ffem,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                height:
                                                                    1.5 *
                                                                    ffem /
                                                                    fem,
                                                                letterSpacing:
                                                                    0.3740000129 *
                                                                    fem,
                                                                color: Color(
                                                                  0xff2c83f1,
                                                                ),
                                                              ),
                                                            );
                                                          }),
                                                          SizedBox(
                                                            width: 9 * fem,
                                                          ),
                                                          InkWell(
                                                            onTap: () {
                                                              shoppingController
                                                                  .productsCartModal[index]
                                                                  .count!
                                                                  .value++;
                                                            },
                                                            child: Container(
                                                              // frame680maR (318:7984)
                                                              width: 29 * fem,
                                                              height:
                                                                  double
                                                                      .infinity,
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  0xff2c83f1,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      40 * fem,
                                                                    ),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  '+',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: SafeGoogleFont(
                                                                    'Roboto',
                                                                    fontSize:
                                                                        16 *
                                                                        ffem,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    height:
                                                                        1.125 *
                                                                        ffem /
                                                                        fem,
                                                                    letterSpacing:
                                                                        0.3740000129 *
                                                                        fem,
                                                                    color: Color(
                                                                      0xffffffff,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        shoppingController
                                                            .productsCartModal
                                                            .removeAt(index);
                                                      },
                                                      child: Container(
                                                        // deletefQu (318:8081)
                                                        width: 36 * fem,
                                                        height: 36 * fem,
                                                        child: Image.asset(
                                                          'assets/images/products/delete-TgM.png',
                                                          width: 36 * fem,
                                                          height: 36 * fem,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : Text(
                                    'No Items Found',
                                    style: SafeGoogleFont(
                                      'Roboto',
                                      fontSize: 14 * ffem,
                                      fontWeight: FontWeight.w500,
                                      height: 1.7142857143 * ffem / fem,
                                      letterSpacing: 0.3740000129 * fem,
                                      color: Color(0xff000000),
                                    ),
                                  );
                            }),
                          ],
                        ),
                      ),
                      Container(
                        // actionbuttonZ4u (318:8200)
                        margin: EdgeInsets.fromLTRB(
                          0 * fem,
                          0 * fem,
                          0 * fem,
                          10 * fem,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          10 * fem,
                          10 * fem,
                          9.5 * fem,
                          10 * fem,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Color(0xffe0eaf6)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              // totalTRB (318:8205)
                              margin: EdgeInsets.fromLTRB(
                                0 * fem,
                                0 * fem,
                                80.5 * fem,
                                0 * fem,
                              ),
                              child: Text(
                                'Total',
                                textAlign: TextAlign.center,
                                style: SafeGoogleFont(
                                  'Roboto',
                                  fontSize: 12 * ffem,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5 * ffem / fem,
                                  letterSpacing: 0.3740000129 * fem,
                                  color: Color(0xff2c83f1),
                                ),
                              ),
                            ),
                            Obx(() {
                              return Text(
                                // KyB (318:8206)
                                '\$${controller.totalPrice!.value}',
                                textAlign: TextAlign.center,
                                style: SafeGoogleFont(
                                  'Roboto',
                                  fontSize: 18 * ffem,
                                  fontWeight: FontWeight.w700,
                                  height: 1 * ffem / fem,
                                  letterSpacing: 0.3740000129 * fem,
                                  color: Color(0xff2c83f1),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      Container(
                        // actionbuttonT3o (318:8104)
                        margin: EdgeInsets.fromLTRB(
                          10 * fem,
                          0 * fem,
                          10 * fem,
                          0 * fem,
                        ),
                        width: double.infinity,
                        height: 36 * fem,
                        child: Row(
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                //  Get.to(CheckoutScreen(type: 'Product'));
                              },
                              child: Container(
                                // productaddtocartZMj (318:8105)
                                margin: EdgeInsets.fromLTRB(
                                  0 * fem,
                                  0 * fem,
                                  13 * fem,
                                  0 * fem,
                                ),
                                width: 70 * fem,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Color(0xff2ac57b),
                                  borderRadius: BorderRadius.circular(50 * fem),
                                ),
                                child: Center(
                                  child: Text(
                                    'Checkout',
                                    textAlign: TextAlign.center,
                                    style: SafeGoogleFont(
                                      'Roboto',
                                      fontSize: 12 * ffem,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5 * ffem / fem,
                                      letterSpacing: 0.3740000129 * fem,
                                      color: Color(0xffffffff),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              // productaddtocartdMb (318:8107)
                              width: 70 * fem,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xffe81a1a)),
                                color: Color(0xfffff2f2),
                                borderRadius: BorderRadius.circular(50 * fem),
                              ),
                              child: Center(
                                child: Text(
                                  'Clear',
                                  textAlign: TextAlign.center,
                                  style: SafeGoogleFont(
                                    'Roboto',
                                    fontSize: 12 * ffem,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5 * ffem / fem,
                                    letterSpacing: 0.3740000129 * fem,
                                    color: Color(0xffe81a1a),
                                  ),
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
            ),
          ],
        ),
      ],
    );
  }
}
