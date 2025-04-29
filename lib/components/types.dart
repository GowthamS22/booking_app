import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/constants.dart';
import '../config/palette.dart';
import '../controllers/auth_controller.dart';
import '../controllers/report_controller.dart';

class Types extends StatefulWidget {

  const Types({
    Key? key,
    required this.closing,
    required this.type,
    required this.dollarOrCoins,
    required this.quantity,
    required this.isNotes,
    required this.isCoins,
    required this.isCents,
  }) : super(key: key);

  final List closing;
  final String type;
  final String dollarOrCoins;
  final List quantity;
  final bool isNotes, isCoins, isCents;

  @override
  State<Types> createState() => _TypesState();
}

class _TypesState extends State<Types> {
  @override
  Widget build(BuildContext context) {

    AuthController authController = Get.find();

    return GetBuilder<ReportController>(
        init: ReportController(),
        builder: (controller) {
          return ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.closing.length,
            separatorBuilder: (BuildContext context, int index) =>
            const Divider(
              thickness: 1,
              color: Palette.lightGrey,
            ),
            itemBuilder: (context, int index) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${widget.dollarOrCoins} ${widget.closing[index]}${(widget.type=='Cents') ? 'C':''}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14*ffem,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${widget.type=='Cents'? 'Coins' : widget.type}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14*ffem,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: () {
                        controller.quantityController.text = '';
                        if (widget.isNotes) {
                          controller.types           = controller.notesQuantity;
                          controller.typeIndex.value = index;
                        } else if (widget.isCoins) {
                          controller.types           = controller.coinsQuantity;
                          controller.typeIndex.value = index;
                        } else {
                          controller.types           = controller.centsQuantity;
                          controller.typeIndex.value = index;
                        }
                        setState((){});
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5.0),
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                            border: Border.all(color: Palette.lightGrey),
                            color: Colors.grey.shade300),
                        child: Text(
                          widget.quantity[index],
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14*ffem,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.type == 'Cents' ?
                      '\$ ${(int.parse(widget.closing[index]) * int.parse(widget.quantity[index]))/100}' :
                      '\$ ${int.parse(widget.closing[index]) * int.parse(widget.quantity[index])}',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14*ffem,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        });
  }
}
