import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../../models/models.dart';
import '../../pages/main/widgets/add_product/provider/add_product_provider.dart';
import '../../pages/main/widgets/right_side/riverpod/right_side_provider.dart';
import '../../theme/app_style.dart';
import '../components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/add_product/add_product_dialog.dart';

class KeywordCheck {
  final bool hasCold;
  final bool hasFrozen;
  KeywordCheck(this.hasCold, this.hasFrozen);
}

class SizeInfo {
  final String? size;
  final Unit? unit;

  SizeInfo(this.size, this.unit);
}

class ProductGridItem extends ConsumerStatefulWidget {
  final ProductData product;

  const ProductGridItem({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends ConsumerState<ProductGridItem> {
  bool _isVisible = true;
  Timer? _timer;
  final GlobalKey _sizeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      setState(() {
        _isVisible = !_isVisible;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _containsKeyword(String? text, String keyword) {
    if (text == null) return false;
    return text.toLowerCase().trim().contains(keyword.toLowerCase());
  }

  String _cleanTitle(String? title) {
    if (title == null) return '';

    String cleanedTitle = title;

    final patterns = [
      RegExp(
          r'\d+(?:\.\d+)?\s*(?:Litre|Liter|L|ml|milliliter|millilitre|kg|kilo|kilogram|g|gram|grams|pack|pck|case|cs)\s*-',
          caseSensitive: false),
      RegExp(
          r'-\s*\d+(?:\.\d+)?\s*(?:Litre|Liter|L|ml|milliliter|millilitre|kg|kilo|kilogram|g|gram|grams|pack|pck|case|cs)',
          caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:Litre|Liter|L)\b', caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:ml|milliliter|millilitre)\b',
          caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:kg|kilo|kilogram)\b', caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:g|gram|grams)\b', caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:pack|pck)\b', caseSensitive: false),
      RegExp(r'\d+(?:\.\d+)?\s*(?:case|cs)\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      cleanedTitle = cleanedTitle.replaceAll(pattern, '');
    }

    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'^-+|-+$'), '');
    cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanedTitle;
  }

  SizeInfo? _extractSize(String? title, Unit? unit) {
    if (title == null) return null;

    final literPattern =
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:Litre|Liter|L)\b', caseSensitive: false);
    final mlPattern = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:ml|milliliter|millilitre)\b',
        caseSensitive: false);
    final kgPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kilo|kilogram)\b',
        caseSensitive: false);
    final gramPattern =
    RegExp(r'(\d+(?:\.\d+)?)\s*(?:g|gram|grams)\b', caseSensitive: false);

    var match = literPattern.firstMatch(title);
    if (match != null) {
      //final size = double.parse(match.group(1)!);
      //return SizeInfo('${size}L', unit);
      return SizeInfo('${match.group(1)}L', unit);
    }

    match = mlPattern.firstMatch(title);
    if (match != null) {
      return SizeInfo('${match.group(1)}ml', unit);
    }

    match = kgPattern.firstMatch(title);
    if (match != null) {
      final size = double.parse(match.group(1)!);
      return SizeInfo('${size}kg', unit);
    }

    match = gramPattern.firstMatch(title);
    if (match != null) {
      final size = double.parse(match.group(1)!);
      if (size >= 1000) {
        return SizeInfo('${size / 1000}kg', unit);
      }
      return SizeInfo('${size}g', unit);
    }

    if (unit != null) {
      return SizeInfo(null, unit);
    }

    return null;
  }

  Widget _buildSizeIndicator(String size, {Key? key}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
      decoration: BoxDecoration(
        color: AppStyle.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        size,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppStyle.white,
        ),
      ),
    );
  }

  Widget _buildUnitText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppStyle.black.withOpacity(0.7),
      ),
    );
  }

  Widget _buildCircularIcon(Color backgroundColor, Color iconColor) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Remix.snowflake_fill,
        color: iconColor,
        size: 16,
      ),
    );
  }

  Widget _buildWarningIcon() {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: const Icon(
        Icons.warning,
        color: AppStyle.black,
        size: 24,
      ),
    );
  }

  KeywordCheck checkKeywords(ProductData product) {
    bool hasCold = false;
    bool hasFrozen = false;

    if (product.stocks?.isNotEmpty ?? false) {
      final firstStock = product.stocks!.first;

      if (firstStock.extras != null) {
        for (final extra in firstStock.extras!) {
          final value = extra.value;
          if (_containsKeyword(value, 'cold')) {
            hasCold = true;
          }
          if (_containsKeyword(value, 'frozen')) {
            hasFrozen = true;
          }
        }
      }

      if (firstStock.addons != null) {
        for (final addon in firstStock.addons!) {
          if (_containsKeyword(addon.product?.translation?.title, 'cold')) {
            hasCold = true;
          }
          if (_containsKeyword(addon.product?.translation?.title, 'frozen')) {
            hasFrozen = true;
          }

          if (_containsKeyword(addon.stocks?.translation?.title, 'cold')) {
            hasCold = true;
          }
          if (_containsKeyword(addon.stocks?.translation?.title, 'frozen')) {
            hasFrozen = true;
          }
        }
      }
    }

    if (_containsKeyword(product.translation?.title, 'cold') ||
        _containsKeyword(product.translation?.description, 'cold')) {
      hasCold = true;
    }
    if (_containsKeyword(product.translation?.title, 'frozen') ||
        _containsKeyword(product.translation?.description, 'frozen')) {
      hasFrozen = true;
    }

    return KeywordCheck(hasCold, hasFrozen);
  }

  @override
  Widget build(BuildContext context) {
    final rightSideState = ref.watch(rightSideProvider);
    final addProductNotifier = ref.read(addProductProvider.notifier);
    final rightSideNotifier = ref.read(rightSideProvider.notifier);

    final int stockQuantity = widget.product.stocks?.first.quantity ?? 0;
    final bool isOutOfStock = widget.product.stocks == null ||
        widget.product.stocks!.isEmpty ||
        stockQuantity == 0;
    final bool isLowStock = !isOutOfStock && stockQuantity < 10;
    final bool hasDiscount = !isOutOfStock &&
        (widget.product.stocks?[0].discount != null &&
            (widget.product.stocks?[0].discount ?? 0) > 0);

    Color backgroundColor;
    Color textColor;
    if (isOutOfStock) {
      backgroundColor = AppStyle.red;
      textColor = AppStyle.white;
    } else if (isLowStock) {
      backgroundColor = AppStyle.orange;
      textColor = AppStyle.black;
    } else {
      backgroundColor = AppStyle.white;
      textColor = AppStyle.black;
    }

    final SizeInfo? sizeInfo = AppConstants.enableJuvoONE
        ? _extractSize(widget.product.translation?.title, widget.product.unit)
        : null;

    Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        color: backgroundColor,
      ),
      constraints: BoxConstraints(
        maxWidth: 227.r,
        maxHeight: AppConstants.enableJuvoONE ? 200.r : 227.r,
      ),
      padding: REdgeInsets.all(10),
      child: Stack(
          children: [
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (AppConstants.enableJuvoONE) ...[
    Expanded(
    child: Stack(
    //fit: StackFit.expand,
      children: [
        CommonImage(
          imageUrl: widget.product.img,
          height: 207,
          width: double.infinity,
          isResponsive: true,
          radius: 10.r,
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _cleanTitle(widget.product.translation?.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppStyle.black,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (sizeInfo != null) ...[
                SizedBox(width: 8.r),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sizeInfo.size != null)
                      _buildSizeIndicator(sizeInfo.size!, key: _sizeKey),
                    if (sizeInfo.unit?.translation?.title != null)
                      SizedBox(height: 4.r),
                    if (sizeInfo.unit?.translation?.title != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final RenderBox? renderBox =
                          _sizeKey.currentContext?.findRenderObject() as RenderBox?;
                          final double width = renderBox?.size.width ?? 0;

                          return SizedBox(
                            width: width > 0 ? width : null,
                            child: Center(
                              child: _buildUnitText(
                                  sizeInfo.unit!.translation!.title!),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
    ),
    ] else ...[
    Expanded(
    child: CommonImage(
    imageUrl: widget.product.img,
    height: 50,
    isResponsive: true,
    ),
    ),
    16.verticalSpace,
    Text(
    '${widget.product.translation?.title}',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    letterSpacing: -14 * 0.02,
    color: textColor,
    ),
    ),
    6.verticalSpace,
    Text(
    isOutOfStock
    ? AppHelpers.getTranslation(TrKeys.outOfStock)
        : '${AppHelpers.getTranslation(TrKeys.inStock)} - $stockQuantity',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: -14 * 0.02,
    color: isOutOfStock ? AppStyle.white : AppStyle.inStockText,
    ),
    ),
    if (!isOutOfStock) ...[
    8.verticalSpace,
    Row(
    children: [
    if (hasDiscount)
    Row(
    children: [
    Text(
      AppHelpers.numberFormat(
          (widget.product.stocks?.first.discount ?? 0) +
              (widget.product.stocks?.first.totalPrice ?? 0)),
      style: GoogleFonts.inter(
        decoration: TextDecoration.lineThrough,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppStyle.discountText,
        letterSpacing: -14 * 0.02,
      ),
    ),
      10.horizontalSpace,
    ],
    ),
      Text(
        AppHelpers.numberFormat(
            widget.product.stocks?.first.totalPrice ?? 0),
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -14 * 0.02,
        ),
      ),
    ],
    ),
    ],
          ],
          ],
          ),
            if (isOutOfStock || isLowStock)
              Positioned(
                top: 0,
                right: 0,
                child: _buildWarningIcon(),
              ),
            if (AppConstants.enableJuvoONE) ...[
              Builder(
                builder: (context) {
                  final keywords = checkKeywords(widget.product);
                  if (keywords.hasFrozen && keywords.hasCold) {
                    return Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildCircularIcon(
                            Colors.blue.shade100,
                            Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          _buildCircularIcon(
                            Colors.indigo.shade100,
                            Colors.indigo.shade700,
                          ),
                        ],
                      ),
                    );
                  } else if (keywords.hasFrozen) {
                    return Positioned(
                      top: 8,
                      left: 8,
                      child: _buildCircularIcon(
                        Colors.indigo.shade100,
                        Colors.indigo.shade700,
                      ),
                    );
                  } else if (keywords.hasCold) {
                    return Positioned(
                      top: 8,
                      left: 8,
                      child: _buildCircularIcon(
                        Colors.blue.shade100,
                        Colors.blue.shade700,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
      ),
    );

    return isOutOfStock
        ? content
        : InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        if (widget.product.stocks?.first.extras?.isEmpty ?? true) {
          addProductNotifier.setProduct(
            widget.product,
            rightSideState.selectedBagIndex,
          );
          addProductNotifier.addProductToBag(
            context,
            rightSideState.selectedBagIndex,
            rightSideNotifier,
          );
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return AddProductDialog(product: widget.product);
            },
          );
        }
      },
      child: content,
    );
  }
}

/// Extension to add helper methods for unit matches
extension UnitExtension on Unit {
  bool get isCase =>
      translation?.title?.toLowerCase().contains('case') ?? false;
  bool get isPack =>
      translation?.title?.toLowerCase().contains('pack') ?? false;
}

/// Extension to add helper methods for string size parsing
extension StringSizeExtension on String {
  static final _numberPattern = RegExp(r'(\d+(?:\.\d+)?)');

  String? extractNumber() {
    final match = _numberPattern.firstMatch(this);
    return match?.group(1);
  }
}

/// Extension to add helper methods for size info formatting
extension SizeInfoExtension on SizeInfo {
  bool get isSpecialUnit => unit?.isCase == true || unit?.isPack == true;

  String? get formattedSize {
    if (size == null) return null;
    if (isSpecialUnit) {
      return size?.extractNumber();
    }
    return size;
  }

  String? get formattedUnit {
    if (unit?.translation?.title == null) return null;
    return unit!.translation!.title!;
  }
}
