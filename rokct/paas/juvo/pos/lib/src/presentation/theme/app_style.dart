import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/constants.dart';

class AppStyle {
  AppStyle._();

  // Color definitions
  static const Color bottomNavigationBarColor = Color(0xFF2C2C2C);
  static const Color enterOrderButton = Color(0xFF2C2C2C);
  static const Color tabBarborder = Color(0xFF3A3A3A);
  static const Color orderButtonColor = Color(0xFFA0A0A0);
  static const Color dotColor = Color(0xFF5A5A5A);
  static const Color switchBg = Color(0xFF4A4A4A);
  static const Color white = Color(0xFF232B2F);
  static const Color transparent = Color(0x00FFFFFF);
  static const Color black = Color(0xFFFFFFFF);
  static const Color icon = Color(0x60E0E0E0);
  static const Color textHint = Color(0xFF7A7A7A);
  static const Color black12 = Color(0x1FFFFFFF);
  static const Color blackWithOpacity = Color(0x20E6E6E6);
  static const Color whiteWithOpacity = Color(0x90232B2F);
  static const Color dontHaveAccBtnBack = Color(0xFF2B343B);
  static const Color mainBack = Color(0xFF1E272E);
  static const Color border = Color(0xFF3A3A3A);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color recommendBg = Color(0xFF3A3A3A);
  static const Color bannerBg = Color(0xFF2C2C2C);
  static const Color bgGrey = Color(0xFF2A2A2A);
  static const Color outlineButtonBorder = Color(0xFF4A4A4A);
  static const Color bottomNavigationBack = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color unselectedBottomItem = Color(0xFF808080);
  static const Color hint = Color(0xFF808080);
  static const Color unselectedTab = Color(0xFFA0A0A0);
  static const Color newStoreDataBorder = Color(0x4A4A4A3A);
  static const Color differBorder = Color(0xFF3A3A3A);
  static const Color starColor = Color(0xFFFFA826);
  static const Color doorColor = Color(0xFFFFC636);
  static const Color dragElement = Color(0xFFE5E5E5);
  static const Color addProductSearchedToBasket =
      Color.fromRGBO(255, 255, 255, 0.62);
  static const Color rate = Color(0xFFFFB800);
  static const Color red = Color(0xFFFF6B6B);
  static const Color redBg = Color(0xFF3A2A2A);
  static const Color blueBonus = Color(0xFF4DA8FF);
  static const Color accentColor = Color(0xFFFF6633);//Color(0xFFFF5722);
  static const Color divider = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color reviewText = Color(0xFFA0A0A0);
  static const Color bannerGradient1 = Color.fromRGBO(255, 255, 255, 0.5);
  static const Color bannerGradient2 = Color.fromRGBO(0, 0, 0, 0);
  static const Color brandTitleDivider = Color(0xFF808080);
  static const Color discountProduct = Color(0xFFFF6B6B);
  static const Color notificationTime = Color(0xFFA0A0A0);
  static const Color separatorDot = Color(0xFF4A4A4A);
  static const Color shimmerBase = Color.fromRGBO(117, 117, 117, 0.29);
  static const Color shimmerHighlight = Color.fromRGBO(194, 194, 194, 0.65);
  static const Color locationAddress = Color(0xFFD0D0D0);
  static const Color selectedItemsText = Color(0xFFB0B0B0);
  static const Color iconButtonBack = Color(0xFF3A3A3A);
  static const Color shadowCart = Color.fromRGBO(0, 0, 0, 0.65);
  static const Color extrasInCart = Color(0xFFA0A0A0);
  static const Color notDoneOrderStatus = Color(0xFF2A2A2A);
  static const Color unselectedBottomBarBack = Color(0xFF2C2C2C);
  static const Color unselectedBottomBarItem = Color(0xFF808080);
  static const Color bottomNavigationShadow = Color.fromRGBO(0, 0, 0, 0.65);
  static const Color profileModalBack = Color(0xFF2A2A2A);
  static const Color arrowRightProfileButton = Color(0xFF4A4A4A);
  static const Color customMarkerShadow = Color.fromRGBO(0, 0, 0, 0.29);
  static const Color selectedTextFromModal = Color(0xFFE0E0E0);
  static const Color verticalDivider = Color(0xFF3A3A3A);
  static const Color unselectedOrderStatus = Color(0xFF3A3A3A);
  static const Color borderRadio = Color(0xFF808080);
  static const Color shippingType = Color(0xFFA0A0A0);
  static const Color attachmentBorder = Color(0xFF4A4A4A);
  static const Color orderStatusProgressBack = Color(0xFF3A3A3A);
  static const Color shadow = Color(0x3F000000);
  static const Color shadowBottom = Color(0x33FFFFFF);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Pillar colors
  static const Color peopleColor = Color(0xFF8E44AD);    // Purple
  static const Color systemsColor = Color(0xFF3498DB);   // Blue
  static const Color financeColor = Color(0xFF2ECC71);   // Green
  static const Color customersColor = Color(0xFFE67E22); // Orange
  static const Color socialColor = Color(0xFFE74C3C);    // Red
  static const Color brown = Colors.brown;    // Brown
  static const Color teal = Colors.teal;    // Teal

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: primary),
    ),
  );

  // Text styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textGrey,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textGrey,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textGrey,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textGrey,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: textHint,
  );

  // Card styles
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: shimmerHighlight,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Input decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // from appcolors
  static const Color editProfileCircle = Color(0xFF2B343B);
  static const Color revenueColor = Color(0xFFFF8A00);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color addButtonColor = Color(0xFF2A2A2A);
  static const Color removeButtonColor = Color(0xFF2A2A2A);
  //static const Color iconColor = Color(0xFFB0B0B0);
  static const Color inStockText = Color(0xFF16AA16);
  static const Color discountText = Color(0xFF808080);
  static const Color invoiceColor = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFF1E272E);
  static const Color greyColor = Color(0xFF2A2A2A);
  static const Color colorGrey = Color.fromRGBO(179, 181, 193, 1);
  static const Color toggleColor = Color(0xFF3A3A3A);
  static const Color toggleShadowColor = Color(0xFF6B6B6B);
  static const Color pendingDark = Color(0xFFF19204);
  static const Color blueColor = Color(0xFF3A92F5);
  static const Color orange = Color(0xFFF26110);
  static const Color differborder = Color(0xFFE0E0E0);

  // Constants from the original AppColors
  static const Color searchHint = Color(0xFF2E3456);
  static const Color shadowSecond = Color(0x45A8A8A9);
  static const Color arrowRight = Color(0xFFD9D9D9);
  static const Color partnerChatBack = Color(0xFF1A222C);
  static const Color yourChatBack = Color(0xFF25303F);

  // Updated brandGreen as a getter
  static Color get brandGreen {
    return AppConstants.enableJuvoONE ? blueBonus : const Color(0xFFFF6600);
  }
  static Color get primary {
    return AppConstants.enableJuvoONE ? blueBonus : const Color(0xFFFF6600);
  }

  //static const Color primary = Color(0xFFFF6600);


  // MaterialColor definitions
  static const MaterialColor green = MaterialColor(
    0xFF16AA16,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF16AA16),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  static const MaterialColor blue = MaterialColor(
    0xFF4DA8FF,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF4DA8FF),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  static const MaterialColor grey = MaterialColor(
    0xFF2A2A2A,
    <int, Color>{
      50: Color(0xFFFAFAFA),
      100: Color(0xFFF5F5F5),
      200: Color(0xFFEEEEEE),
      300: Color(0xFFE0E0E0),
      400: Color(0xFFBDBDBD),
      500: Color(0xFF9E9E9E),
      600: Color(0xFF757575),
      700: Color(0xFF616161),
      800: Color(0xFF424242),
      900: Color(0xFF212121),
    },
  );

  static const success = Color(0xff31D0AA);

  /// dark theme based colors
  static const Color mainBackDark = Color(0xFF1E272E);
  static const Color dontHaveAnAccBackDark = Color(0xFF2B343B);
  static const Color dragElementDark = Color(0xFFE5E5E5);
  static const Color shimmerBaseDark = Color.fromRGBO(117, 117, 117, 0.29);
  static const Color shimmerHighlightDark = Color.fromRGBO(194, 194, 194, 0.65);
  static const Color borderDark = Color(0xFF494B4D);



  /// font styles
  static interBold(
          {double size = 18,
          Color color = AppStyle.black,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: TextDecoration.none);

  static interSemi(
          {double size = 18,
          Color color = AppStyle.black,
          TextDecoration decoration = TextDecoration.none,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: decoration);

  static interNoSemi(
          {double size = 18,
          Color color = AppStyle.black,
          TextDecoration decoration = TextDecoration.none,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size.sp,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: decoration);

  static interNormal(
          {double size = 16,
          Color color = AppStyle.black,
          TextDecoration textDecoration = TextDecoration.none,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size.sp,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: textDecoration);

  static interRegular(
          {double size = 16,
          Color color = AppStyle.black,
          TextDecoration textDecoration = TextDecoration.none,
          double letterSpacing = 0}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w400,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: textDecoration);


  ///Juvo Font Styles - Using Montserrat
  static logoFontBold({
    double size = 18,
    Color color = AppStyle.black,
    double letterSpacing = 0
  }) =>
      GoogleFonts.montserrat(
          fontSize: size.sp,
          fontWeight: FontWeight.w700, // Bold 700
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: TextDecoration.none
      );

  static logoFontBoldItalic({
    double size = 18,
    Color color = AppStyle.black,
    double letterSpacing = 0
  }) =>
      GoogleFonts.montserrat(
          fontSize: size.sp,
          fontWeight: FontWeight.w700, // Bold 700
          fontStyle: FontStyle.italic,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: TextDecoration.none
      );

  static logoFontBlackItalic({
    double size = 18,
    Color color = AppStyle.black,
    double letterSpacing = 0
  }) =>
      GoogleFonts.montserrat(
          fontSize: size.sp,
          fontWeight: FontWeight.w900, // Black 900
          fontStyle: FontStyle.italic,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: TextDecoration.none
      );

// Logo Motto styles - Using Montserrat
  static logoMottoRegular({
    double size = 16,
    Color color = AppStyle.black,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0
  }) =>
      GoogleFonts.montserrat(
          fontSize: size.sp,
          fontWeight: FontWeight.w400, // Regular 400
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: textDecoration
      );

  static logoMottoRegularItalic({
    double size = 16,
    Color color = AppStyle.black,
    TextDecoration textDecoration = TextDecoration.none,
    double letterSpacing = 0
  }) =>
      GoogleFonts.montserrat(
          fontSize: size.sp,
          fontWeight: FontWeight.w400, // Regular 400
          fontStyle: FontStyle.italic,
          color: color,
          letterSpacing: letterSpacing.sp,
          decoration: textDecoration
      );

}

