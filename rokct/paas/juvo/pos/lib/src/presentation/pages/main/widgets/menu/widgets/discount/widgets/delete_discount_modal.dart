// import 'package:flutter/material.dart';
// import 'package:auto_route/auto_route.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:admin_desktop/src/core/constants/constants.dart';
// import 'package:admin_desktop/src/core/utils/app_helpers.dart';
//
// class DeleteDiscountModal extends StatelessWidget {
//   final int id;
//
//   const DeleteDiscountModal({super.key, required this.id});
//
//   @override
//   Widget build(BuildContext context) {
//     return ModalWrap(
//       body: Padding(
//         padding: REdgeInsets.symmetric(horizontal: 16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const ModalDrag(),
//             40.verticalSpace,
//             Text(
//               '${AppHelpers.getTranslation(TrKeys.areYouSureToDelete)}?',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(
//                 fontSize: 18,
//                 color: AppStyle.black,
//                 fontWeight: FontWeight.w500,
//                 letterSpacing: -14 * 0.02,
//               ),
//             ),
//             36.verticalSpace,
//             Row(
//               children: [
//                 Expanded(
//                   child: CustomButton(
//                     title: TrKeys.cancel,
//                     onPressed: context.maybePop,
//                     background: AppStyle.transparent,
//                     border: AppStyle.black,
//                     textColor: AppStyle.textColor,
//                   ),
//                 ),
//                 16.horizontalSpace,
//                 Expanded(
//                   child: Consumer(
//                     builder: (context, ref, child) {
//                       return CustomButton(
//                         title: AppHelpers.getTranslation(TrKeys.yes),
//                         isLoading: ref.watch(discountProvider).isLoading,
//                         onPressed: () {
//                           ref
//                               .read(discountProvider.notifier)
//                               .deleteDiscount(context, id);
//                           Navigator.pop(context);
//                         },
//                         background: AppStyle.red,
//                         border: AppStyle.red,
//                         textColor: AppStyle.white,
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             40.verticalSpace,
//           ],
//         ),
//       ),
//     );
//   }
// }

