import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:foodyman/infrastructure/services/local_storage.dart';
import 'package:foodyman/infrastructure/services/tr_keys.dart';
import 'package:foodyman/presentation/components/custom_tab_bar.dart';
import 'package:foodyman/presentation/theme/theme.dart';
import 'widgets/order_delivery.dart';
import 'widgets/order_pick_up.dart';
import 'widgets/order_pickup_point.dart';

class OrderType extends StatefulWidget {
  final ValueChanged<bool> onChange;
  final VoidCallback getLocation;
  final TabController tabController;
  final int shopId;
  final bool sendUser;

  const OrderType({
    super.key,
    required this.onChange,
    required this.getLocation,
    required this.tabController,
    required this.shopId,
    required this.sendUser,
  });

  @override
  State<OrderType> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderType> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _tabs = [
      Tab(text: AppHelpers.getTranslation(TrKeys.delivery)),
      Tab(text: AppHelpers.getTranslation(TrKeys.pickup)),
      Tab(text: AppHelpers.getTranslation(TrKeys.pickup_point)),
    ];

    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(top: 16.r, right: 16.r, left: 16.r),
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTabBar(
              tabController: widget.tabController,
              tabs: _tabs,
            ),
            SizedBox(
              height: _calculateHeight(),
              child: TabBarView(controller: widget.tabController, children: [
                OrderDelivery(
                  onChange: widget.onChange,
                  getLocation: widget.getLocation,
                  shopId: widget.shopId,
                ),
                const OrderPickUp(),
                const OrderPickupPoint(),
              ]),
            )
          ],
        ),
      ),
    );
  }

  double _calculateHeight() {
    switch (widget.tabController.index) {
      case 0: // Delivery
        return widget.sendUser ? 300 + 268.h : 300 + 200.h;
      case 1: // Pickup
        return 48 + 360.h;
      case 2: // Pickup Point
        return 48 + 450.h; // Height for map view
      default:
        return 300 + 200.h;
    }
  }
}