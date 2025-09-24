import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../../models/models.dart';
import '../../../../components/components.dart';
import '../../../../theme/theme.dart';
import '../right_side/riverpod/right_side_provider.dart';
import 'provider/add_product_provider.dart';
import 'riverpod/add_product_state.dart';
import 'widgets/w_ingredient.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final ProductData? product;

  const AddProductDialog({super.key, required this.product});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addProductProvider.notifier).setProduct(
        widget.product,
        ref.watch(rightSideProvider).selectedBagIndex,
      );
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundFile) async {
    if (AppConstants.sound) {
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundFile'));
        print('Playing sound: $soundFile'); // Debug print
      } catch (e) {
        print('Error playing sound: $e'); // Debug print
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductProvider);
    final rightSideState = ref.watch(rightSideProvider);
    final notifier = ref.read(addProductProvider.notifier);
    final rightSideNotifier = ref.read(rightSideProvider.notifier);
    final List<Stocks> stocks = state.product?.stocks ?? <Stocks>[];

    if (stocks.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: AppStyle.white,
          ),
          constraints: BoxConstraints(
            maxHeight: 700.r,
            maxWidth: 600.r,
          ),
          padding: REdgeInsets.symmetric(horizontal: 40, vertical: 50),
          child: Text(
            '${state.product?.translation?.title} ${AppHelpers.getTranslation(TrKeys.outOfStock).toLowerCase()}',
          ),
        ),
      );
    }

    final bool hasDiscount = (state.selectedStock?.discount != null &&
        (state.selectedStock?.discount ?? 0) > 0);
   // final double totalPrice = calculateTotalPrice(state);
    final String price = AppHelpers.numberFormat(hasDiscount
        ? (state.selectedStock?.totalPrice ?? 0)
        : state.selectedStock?.price,
    );
    final lineThroughPrice = AppHelpers.numberFormat(
        state.selectedStock?.price,
    );
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppStyle.white,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height / 1.6,
          maxWidth: MediaQuery.of(context).size.width / 1.6,
        ),
        padding: REdgeInsets.symmetric(horizontal: 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              20.verticalSpace,
              Row(
                children: [
                  const SizedBox.shrink(),
                  const Spacer(),
                  CircleIconButton(
                    size: 60,
                    backgroundColor: AppStyle.transparent,
                    iconData: FlutterRemix.close_circle_line,
                    icon: AppStyle.black,
                    onTap: () {
                      _playSound('wrong.wav');
                      context.maybePop();
                    },
                  ),
                ],
              ),
              6.verticalSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonImage(
                        imageUrl: widget.product?.img,
                        width: 250,
                        height: 250,
                      ),
                      24.verticalSpace,
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: (AppConstants.enableJuvoONE) ? AppStyle.blue[900]! : AppStyle.icon),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                notifier.decreaseStockCount(
                                    rightSideState.selectedBagIndex);
                                _playSound('tap.wav');
                                setState(() {});
                              },
                              icon: const Icon(FlutterRemix.subtract_line),
                            ),
                            13.horizontalSpace,
                            Text(
                              '${state.stockCount}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 18.sp,
                                color: AppStyle.black,
                                letterSpacing: -0.4,
                              ),
                            ),
                            12.horizontalSpace,
                            IconButton(
                              onPressed: () {
                                int maxQuantity = state.selectedStock?.quantity ?? 0;
                                print('Current count: ${state.stockCount}, Max quantity: $maxQuantity'); // Debug print
                                if (state.stockCount < maxQuantity) {
                                  notifier.increaseStockCount(
                                      rightSideState.selectedBagIndex);
                                  _playSound('tap.wav');
                                } else {
                                  print('Maximum quantity reached, playing wrong.wav'); // Debug print
                                  _playSound('wrong.wav');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Maximum quantity reached')),
                                  );
                                }
                                setState(() {});
                              },
                              icon: const Icon(FlutterRemix.add_line),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  32.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.product?.translation?.title}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 22.sp,
                            color: AppStyle.black,
                            letterSpacing: -0.4,
                          ),
                        ),
                        8.verticalSpace,
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.6 - 370.w,
                          child: Text(
                            '${widget.product?.translation?.description}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                              color: (AppConstants.enableJuvoONE) ? AppStyle.black.withOpacity(0.5) : AppStyle.icon,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        8.verticalSpace,
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.6 - 370.w,
                          child: Divider(
                            color: AppStyle.black.withOpacity(0.2),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.6 - 370.w,
                          child: ListView.builder(
                            physics: const CustomBouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: state.typedExtras.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final TypedExtra typedExtra = state.typedExtras[index];
                              return ExtraDropdown(
                                typedExtra: typedExtra,
                                onChanged: (UiExtra? newValue) {
                                  if (newValue != null) {
                                    notifier.updateSelectedIndexes(
                                      index: typedExtra.groupIndex,
                                      value: newValue.index,
                                      bagIndex: rightSideState.selectedBagIndex,
                                    );
                                    _playSound('tap.wav');
                                    setState(() {});
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        8.verticalSpace,
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.6 - 370.w,
                          child: WIngredientScreen(
                            list: state.selectedStock?.addons ?? [],
                            onChange: (int value) {
                              notifier.updateIngredient(context, value);
                              _playSound('tap.wav');
                              setState(() {});
                            },
                            add: (int value) {
                              notifier.addIngredient(context, value);
                              _playSound('tap.wav');
                              setState(() {});
                            },
                            remove: (int value) {
                              notifier.removeIngredient(context, value);
                              _playSound('wrong.wav');
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              10.verticalSpace,
              const Divider(),
              10.verticalSpace,
              Row(
                children: [
                  SizedBox(
                    width: 120.w,
                    child: LoginButton(
                      isLoading: state.isLoading,
                      title: AppHelpers.getTranslation(TrKeys.add),
                      onPressed: () {
                        try {
                          notifier.addProductToBag(
                            context,
                            rightSideState.selectedBagIndex,
                            rightSideNotifier,
                          );
                          _playSound('tap.wav');
                        } catch (e) {
                          _playSound('wrong.wav');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add product: ${e.toString()}')),
                          );
                        } finally {
                          context.maybePop();
                        }
                      },
                      bgColor: (AppConstants.enableJuvoONE) ? AppStyle.blue[900] : AppStyle.brandGreen,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppHelpers.getTranslation(TrKeys.price)}:',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppStyle.black,
                          letterSpacing: -14 * 0.02,
                        ),
                      ),
                      4.verticalSpace,
                      Row(
                        children: [
                          if (hasDiscount)
                            Row(
                              children: [
                                Text(
                                  lineThroughPrice,
                                  style: GoogleFonts.inter(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppStyle.discountText,
                                    letterSpacing: -14 * 0.02,
                                  ),
                                ),
                                10.horizontalSpace,
                              ],
                            ),
                          Text(
                            price,
                            style: GoogleFonts.inter(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w600,
                              color: AppStyle.black,
                              letterSpacing: -14 * 0.02,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  double calculateTotalPrice(AddProductState state) {
    num basePrice = state.selectedStock?.totalPrice ?? 0;
    double extrasPrice = 0;

    // Calculate price for extras
    for (var extra in state.typedExtras) {
      for (var uiExtra in extra.uiExtras) {
        if (uiExtra.isSelected) {
          extrasPrice += double.tryParse(uiExtra.value) ?? 0;
        }
      }
    }

    // Calculate price for ingredients
    double ingredientsPrice = 0;
    for (var addon in state.selectedStock?.addons ?? []) {
      ingredientsPrice += addon.price * addon.quantity;
    }

    return (basePrice + extrasPrice + ingredientsPrice) * state.stockCount;
  }
}

class ExtraDropdown extends StatelessWidget {
  final TypedExtra typedExtra;
  final ValueChanged<UiExtra?> onChanged;

  const ExtraDropdown({
    super.key,
    required this.typedExtra,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: REdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<UiExtra>(
    decoration: InputDecoration(
    labelText: typedExtra.title,
    contentPadding: REdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    ),
    ),
      items: typedExtra.uiExtras.map((UiExtra uiExtra) {
        return DropdownMenuItem<UiExtra>(
          value: uiExtra,
          child: Text(uiExtra.value),
        );
      }).toList(),
      onChanged: onChanged,
      selectedItemBuilder: (BuildContext context) {
        return typedExtra.uiExtras.map<Widget>((UiExtra uiExtra) {
          return Text(uiExtra.value);
        }).toList();
      },
      isDense: true,
    ),
    );
  }
}
