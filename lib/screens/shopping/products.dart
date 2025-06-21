import 'package:booking_app/controllers/shopping_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/constants.dart';
import '../../config/google-fonts.dart';
import '../../config/palette.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/shimmer/shimmer_table_loading.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  void initState() {
    // TODO: implement initState
    // print(shoppingController.products.length);

    // Future.delayed(Duration(seconds: 5), () {
    //   shoppingController.productsList.bindStream(
    //       shoppingController.getProducts('venkat'));
    //   print('length after 5 seconds ${shoppingController.products.length}');
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
    // return Container(
    //   // tileblocknnm (137:828)
    //   width: double.infinity,
    //   height: 456.96 * fem,
    //   child: Container(
    //     // productviewLJV (318:8030)
    //     margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 10 * fem, 0 * fem),
    //     width: 662 * fem,
    //     height: double.infinity,
    //     // color: Colors.red,
    //     child: GetBuilder<ShoppingController>(
    //       builder: (controller) {
    //         return Obx(() {
    //           if (controller.tabController == null ||
    //               controller.productsList.isEmpty) {
    //             return const SizedBox(); // or show a loader
    //           }
    //           return controller.productsList.isNotEmpty
    //               ? GridView.builder(
    //                 shrinkWrap: true,
    //                 itemCount: controller.productsList.length,
    //                 gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    //                   maxCrossAxisExtent:
    //                       MediaQuery.of(context).size.width / 5, //
    //                   childAspectRatio: fem / 1.53,
    //                   crossAxisSpacing: 10,
    //                   mainAxisSpacing: 10,
    //                 ),
    //                 itemBuilder: (context, int index) {
    //                   return Container(
    //                     // prorow01B4D (318:8207)
    //                     width: double.infinity,
    //                     height: 200 * fem,
    //                     child: Container(
    //                       // productcardv1o (310:7872)
    //                       margin: EdgeInsets.fromLTRB(
    //                         0 * fem,
    //                         0 * fem,
    //                         7.33 * fem,
    //                         0 * fem,
    //                       ),
    //                       padding: EdgeInsets.fromLTRB(
    //                         12 * fem,
    //                         10 * fem,
    //                         12 * fem,
    //                         12 * fem,
    //                       ),
    //                       width: 160 * fem,
    //                       height: double.infinity,
    //                       decoration: BoxDecoration(
    //                         border: Border.all(color: Color(0xffb3c9e8)),
    //                         color: Color(0xffffffff),
    //                         borderRadius: BorderRadius.circular(10 * fem),
    //                       ),
    //                       child: Column(
    //                         crossAxisAlignment: CrossAxisAlignment.center,
    //                         mainAxisSize: MainAxisSize.min,
    //                         children: [
    //                           Flexible(
    //                             child: Container(
    //                               // autogroup2hdsCV7 (2rujieG5SasaZrgz152hDs)
    //                               width: double.infinity,
    //                               height: 70 * fem,
    //                               child: Stack(
    //                                 children: [
    //                                   Positioned(
    //                                     // drink1Yos (1:641)
    //                                     left: 0 * fem,
    //                                     top: 0,
    //                                     child: Align(
    //                                       child: SizedBox(
    //                                         width: 120 * fem,
    //                                         height: 70 * fem,
    //                                         child:
    //                                             controller
    //                                                     .productsList[index]
    //                                                     .imageUrl!
    //                                                     .isEmpty
    //                                                 ? Image.asset(
    //                                                   'assets/images/products/product_image_coming_soon.jpeg',
    //                                                   fit: BoxFit.contain,
    //                                                 )
    //                                                 : CachedNetworkImage(
    //                                                   imageUrl:
    //                                                       "${controller.productsList[index].imageUrl!}",
    //                                                   fit: BoxFit.contain,
    //                                                   progressIndicatorBuilder:
    //                                                       (
    //                                                         context,
    //                                                         url,
    //                                                         downloadProgress,
    //                                                       ) => Center(
    //                                                         child: SizedBox(
    //                                                           height: 20,
    //                                                           width: 20,
    //                                                           child: CircularProgressIndicator(
    //                                                             value:
    //                                                                 downloadProgress
    //                                                                     .progress,
    //                                                           ),
    //                                                         ),
    //                                                       ),
    //                                                   errorWidget:
    //                                                       (
    //                                                         context,
    //                                                         url,
    //                                                         error,
    //                                                       ) => FittedBox(
    //                                                         fit: BoxFit.contain,
    //                                                         child: Icon(
    //                                                           Icons.error,
    //                                                           color:
    //                                                               Palette
    //                                                                   .dangerTxt,
    //                                                         ),
    //                                                       ),
    //                                                 ),
    //                                       ),
    //                                     ),
    //                                   ),
    //                                   Positioned(
    //                                     // discountdivFiH (310:7848)
    //                                     left: 80 * fem,
    //                                     top: 0 * fem,
    //                                     child: Container(
    //                                       width: 29 * fem,
    //                                       height: 18 * fem,
    //                                       decoration: BoxDecoration(
    //                                         color: Color(0xffe12f2f),
    //                                         borderRadius: BorderRadius.circular(
    //                                           5 * fem,
    //                                         ),
    //                                       ),
    //                                       child: Center(
    //                                         child: Text(
    //                                           '-${controller.productsList[index].discountPercentage?.toStringAsFixed(1)}%',
    //                                           textAlign: TextAlign.center,
    //                                           style: SafeGoogleFont(
    //                                             'Roboto',
    //                                             fontSize: 8 * ffem,
    //                                             fontWeight: FontWeight.w400,
    //                                             height: 2.25 * ffem / fem,
    //                                             letterSpacing:
    //                                                 0.3740000129 * fem,
    //                                             color: Color(0xffffffff),
    //                                           ),
    //                                         ),
    //                                       ),
    //                                     ),
    //                                   ),
    //                                 ],
    //                               ),
    //                             ),
    //                           ),
    //                           SizedBox(height: 1 * fem),
    //                           Container(
    //                             // frame677uXw (310:7871)
    //                             margin: EdgeInsets.fromLTRB(
    //                               0 * fem,
    //                               0 * fem,
    //                               7 * fem,
    //                               0 * fem,
    //                             ),
    //                             child: Column(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 Container(
    //                                   // pricesec3PF (310:7868)
    //                                   margin: EdgeInsets.fromLTRB(
    //                                     0 * fem,
    //                                     0 * fem,
    //                                     0 * fem,
    //                                     7 * fem,
    //                                   ),
    //                                   child: Row(
    //                                     crossAxisAlignment:
    //                                         CrossAxisAlignment.center,
    //                                     children: [
    //                                       Container(
    //                                         // BVT (310:7849)
    //                                         margin: EdgeInsets.fromLTRB(
    //                                           0 * fem,
    //                                           0 * fem,
    //                                           3 * fem,
    //                                           0 * fem,
    //                                         ),
    //                                         child: Text(
    //                                           '\$${controller.productsList[index].salePrice}',
    //                                           style: SafeGoogleFont(
    //                                             'Roboto',
    //                                             fontSize: 14 * ffem,
    //                                             fontWeight: FontWeight.w700,
    //                                             height:
    //                                                 1.2857142857 * ffem / fem,
    //                                             letterSpacing:
    //                                                 0.3740000129 * fem,
    //                                             color: Color(0xff000000),
    //                                           ),
    //                                         ),
    //                                       ),
    //                                       Container(
    //                                         // VW9 (310:7850)
    //                                         margin: EdgeInsets.fromLTRB(
    //                                           0 * fem,
    //                                           0 * fem,
    //                                           4 * fem,
    //                                           0 * fem,
    //                                         ),
    //                                         child: Text(
    //                                           '\$${controller.productsList[index].price}',
    //                                           style: SafeGoogleFont(
    //                                             'Roboto',
    //                                             fontSize: 12 * ffem,
    //                                             fontWeight: FontWeight.w400,
    //                                             height: 1.5 * ffem / fem,
    //                                             letterSpacing:
    //                                                 0.3740000129 * fem,
    //                                             decoration:
    //                                                 TextDecoration.lineThrough,
    //                                             color: Color(0xff637185),
    //                                             decorationColor: Color(
    //                                               0xff637185,
    //                                             ),
    //                                           ),
    //                                         ),
    //                                       ),
    //                                       SizedBox(
    //                                         width: 40,
    //                                         child: Text(
    //                                           // mlQND (318:8047)
    //                                           '${controller.productsList[index].description}',
    //                                           overflow: TextOverflow.ellipsis,
    //                                           style: SafeGoogleFont(
    //                                             'Roboto',
    //                                             fontSize: 9 * ffem,
    //                                             fontWeight: FontWeight.w400,
    //                                             height: 2 * ffem / fem,
    //                                             letterSpacing:
    //                                                 0.3740000129 * fem,
    //                                             color: Color(0xff637185),
    //                                           ),
    //                                         ),
    //                                       ),
    //                                     ],
    //                                   ),
    //                                 ),
    //                                 SizedBox(
    //                                   height: 40,
    //                                   child: Text(
    //                                     // gatoradesportsYjK (310:7866)
    //                                     '${controller.productsList[index].name}',
    //                                     maxLines: 2,
    //                                     textAlign: TextAlign.center,
    //                                     style: SafeGoogleFont(
    //                                       'Roboto',
    //                                       fontSize: 14 * ffem,
    //                                       fontWeight: FontWeight.w700,
    //                                       height: 1.2857142857 * ffem / fem,
    //                                       letterSpacing: 0.3740000129 * fem,
    //                                       color: Color(0xff000000),
    //                                     ),
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                           ),
    //                           SizedBox(height: 1 * fem),
    //                           TextButton(
    //                             // productaddtocartGvD (318:8006)
    //                             onPressed: () {
    //                               print(
    //                                 'checking the description on press button pressed ${controller.productsList[index].description}',
    //                               );
    //
    //                               controller.productsCartModal.add(
    //                                 controller.productsList[index],
    //                               );
    //                             },
    //                             style: TextButton.styleFrom(
    //                               padding: EdgeInsets.zero,
    //                             ),
    //                             child: Container(
    //                               width: double.infinity,
    //                               height: 36 * fem,
    //                               decoration: BoxDecoration(
    //                                 color: Color(0xff2c83f1),
    //                                 borderRadius: BorderRadius.circular(
    //                                   50 * fem,
    //                                 ),
    //                               ),
    //                               child: Center(
    //                                 child: Text(
    //                                   'Add to cart',
    //                                   textAlign: TextAlign.center,
    //                                   style: SafeGoogleFont(
    //                                     'Roboto',
    //                                     fontSize: 12 * ffem,
    //                                     fontWeight: FontWeight.w600,
    //                                     height: 1.5 * ffem / fem,
    //                                     letterSpacing: 0.3740000129 * fem,
    //                                     color: Color(0xffffffff),
    //                                   ),
    //                                 ),
    //                               ),
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   );
    //                 },
    //               )
    //               : ShimmerTableLoading(columnCount: 5, rowCount: 4);
    //         });
    //       },
    //     ),
    //   ),
    // );
  }
}
