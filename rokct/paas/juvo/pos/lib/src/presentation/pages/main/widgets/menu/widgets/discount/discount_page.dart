import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/discount/riverpod/discount/edit_discount/edit_discount_provider.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'add_discount/add_discount_page.dart';
import 'edit_discount/edit_discount_page.dart';
import 'riverpod/discount/discount_provider.dart';
import 'widgets/discount_item.dart';

class DiscountPage extends ConsumerStatefulWidget {
  const DiscountPage({super.key});

  @override
  ConsumerState<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends ConsumerState<DiscountPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(discountProvider.notifier)
          .fetchDiscounts(context: context, isRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.bg,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.discount),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 22.sp,
                    color: AppStyle.black),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(FlutterRemix.close_fill))
            ],
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final discountState = ref.watch(discountProvider);
                final discountEvent = ref.read(discountProvider.notifier);
                return discountState.isLoading
                    ? const Center(child: Loading())
                    : discountState.discounts.isEmpty
                        ? const NoItem(title: TrKeys.noDiscount)
                        : AnimationLimiter(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  ListView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: REdgeInsets.only(
                                        top: 16,
                                        bottom: 56.r,
                                        left: 12,
                                        right: 12),
                                    shrinkWrap: true,
                                    itemCount: discountState.discounts.length,
                                    itemBuilder: (context, index) =>
                                        AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: AppConstants.animationDuration,
                                      child: ScaleAnimation(
                                        scale: 0.5,
                                        child: FadeInAnimation(
                                          child: DiscountItem(
                                            discountData:
                                                discountState.discounts[index],
                                            spacing: 10,
                                            onTap: () {
                                              ref
                                                  .read(editDiscountProvider
                                                      .notifier)
                                                  .setDiscountDetails(
                                                      discountState
                                                          .discounts[index],
                                                      (fullBrand) {});
                                              AppHelpers.showAlertDialog(
                                                  context: context,
                                                  child: SizedBox(
                                                    height: MediaQuery.sizeOf(context).height/1.5,
                                                    width: MediaQuery.sizeOf(context).width/2,
                                                    child: EditDiscountPage(
                                                        discountState
                                                            .discounts[index]
                                                            .id ?? 0),
                                                  )
                                              );
                                            },
                                            onDelete: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    titlePadding: const EdgeInsets.all(16),
                                                    actionsPadding: const EdgeInsets.all(16),
                                                    title: Text(
                                                      AppHelpers.getTranslation(TrKeys.deleteProduct),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 18,
                                                        color: AppStyle.black,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    actions: [
                                                      SizedBox(
                                                        width: 112.r,
                                                        child: ConfirmButton(
                                                            paddingSize: 0,
                                                            title: AppHelpers.getTranslation(TrKeys.no),
                                                            onTap: () => Navigator.pop(context)),
                                                      ),
                                                      SizedBox(
                                                        width: 112.r,
                                                        child: ConfirmButton(
                                                            paddingSize: 0,
                                                            title: AppHelpers.getTranslation(TrKeys.yes),
                                                            onTap: () {
                                                              ref
                                                                  .read(discountProvider.notifier)
                                                                  .deleteDiscount(context, discountState.discounts[index].id ?? 0);

                                                              Navigator.pop(context);
                                                            }),
                                                      ),
                                                    ],
                                                  )
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  HasMoreButton(hasMore: discountState.hasMore, onViewMore:()=> discountEvent.fetchDiscounts(context: context))
                                ],
                              ),
                            ),
                          );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppHelpers.showAlertDialog(
              context: context,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height/1.5,
                width: MediaQuery.sizeOf(context).width/2,
                child: const AddDiscountPage(),
              ));
          //notifier.addTextField();
        },
        backgroundColor: AppStyle.primary,
        child: const Icon(FlutterRemix.add_fill),
      ),
    );
  }
}

