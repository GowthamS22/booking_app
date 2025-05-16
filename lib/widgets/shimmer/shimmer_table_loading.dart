import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/palette.dart';

class ShimmerTableLoading extends StatelessWidget {
  int columnCount;
  int rowCount;

  ShimmerTableLoading({required this.columnCount,required this.rowCount});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Palette.lightGrey,
      highlightColor: Palette.mediumGrey,
      child: DataTable(
        columns: List<DataColumn>.generate(int.parse(columnCount.toString()),(index) =>
            DataColumn(
                label: Container(
                  height: 40.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  child: Text('Column 1'),
                )
            )
        ),
        rows: List<DataRow>.generate(int.parse(rowCount.toString()),(index) {
          return DataRow(cells: List<DataCell>.generate(int.parse(columnCount.toString()), (index) =>
              DataCell(Container(
                height: 40.0,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
              )),
          ));
        },
        ),
      ),
    );
  }
}
