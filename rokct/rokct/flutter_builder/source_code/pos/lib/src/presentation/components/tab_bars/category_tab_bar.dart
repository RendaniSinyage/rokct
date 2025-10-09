import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../generated/assets.dart';
import '../../theme/theme.dart';
import '../list_items/shop_tab_bar_item.dart';

class CategoryTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onTap;

  const CategoryTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.onTap,
    this.index = 0,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.greyColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.w),
          topRight: Radius.circular(16.w),
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16.r, end: 8.r),
            child: SvgPicture.asset(
              Assets.svgMenu,
              width: 22.r,
              height: 22.r,
            ),
          ),
          TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            onTap: onTap,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            isScrollable: true,
            indicatorPadding: EdgeInsets.zero,
            indicatorColor: AppStyle.transparent,
            labelColor: AppStyle.primary,
            unselectedLabelColor: AppStyle.white,
            controller: tabController,
            tabs: [
              ...tabs.map(
                (e) => ShopTabBarItem(
                  title: e,
                  isActive: index == tabs.indexOf(e),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

