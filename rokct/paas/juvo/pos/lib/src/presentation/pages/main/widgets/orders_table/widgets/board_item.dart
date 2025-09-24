// ignore_for_file: non_constant_identifier_names

import 'package:admin_desktop/src/presentation/pages/main/widgets/orders_table/widgets/drag_item.dart';
import 'package:drag_and_drop_lists/drag_and_drop_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import '../../../../../../models/data/order_data.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';

BoardItem({
  required List<OrderData> list,
  required BuildContext context,
  required bool hasMore,
  required bool isLoading,
  required VoidCallback onViewMore,
}) {
  return list.isNotEmpty || isLoading
      ? [
          ...list
              .map((OrderData item) => DragAndDropItem(
                    canDrag: true,
                    child: DragItem(orderData: item),
            feedbackWidget: DragItem(orderData: item,isDrag: true,),
                  ))
              ,
          if (isLoading)
            for (int i = 0; i < 3; i++)
              DragAndDropItem(
                canDrag: false,
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppStyle.shimmerBase,
                  ),
                  margin: const EdgeInsets.all(6),
                  child: const SizedBox(
                    width: double.infinity,
                  ),
                ),
              ),
          (hasMore
              ? DragAndDropItem(
                  child: Material(
                    borderRadius: BorderRadius.circular(10),
                    color: AppStyle.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onViewMore(),
                      child: Container(
                        margin:
                            const EdgeInsets.only(right: 8, left: 8, top: 8),
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppStyle.black.withOpacity(0.17),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppHelpers.getTranslation(TrKeys.viewMore),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppStyle.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : DragAndDropItem(child: const SizedBox())),
          DragAndDropItem(
            canDrag: false,
            child: const SizedBox(height: 100),
          ),
        ]
      : [
          DragAndDropItem(
            canDrag: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 200),
                child: Text(
                  AppHelpers.getTranslation(TrKeys.emptyOrders),
                ),
              ),
            ),
          ),
        ];
}

