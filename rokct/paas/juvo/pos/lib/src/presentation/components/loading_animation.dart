import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../theme/app_style.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> preloadFont() async {
  await GoogleFonts.pendingFonts([
    GoogleFonts.nunito(),
    GoogleFonts.roboto(),
  ]);
}

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  _LoadingAnimationState createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _fontLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationDuration * 11,
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    preloadFont().then((_) {
      if (mounted) {
        setState(() {
          _fontLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double getResponsiveFontSize(BuildContext context, {bool isMainText = true}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = isMainText ? 0.2 : 0.05;  // 15% for main text, 5% for secondary
    double fontSize = screenWidth * scaleFactor;
    return isMainText
        ? fontSize.clamp(40, 80)  // Larger range for main text
        : fontSize.clamp(12, 24);  // Smaller range for secondary text
  }

  TextStyle getMainTextStyle(BuildContext context, Color color) {
    final fontSize = getResponsiveFontSize(context, isMainText: true);
    return _fontLoaded
        ? GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
    )
        : TextStyle(
      fontFamily: 'Sans-serif',
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  TextStyle getSecondaryTextStyle(BuildContext context) {
    final fontSize = getResponsiveFontSize(context, isMainText: false);
    return _fontLoaded
        ? GoogleFonts.roboto(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppStyle.black,
    )
        : TextStyle(
      fontFamily: 'Sans-serif',
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: AppStyle.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + (_animation.value * 0.5),
            child: Transform.scale(
              scale: 0.95 + (_animation.value * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Juvo',
                        style: getMainTextStyle(context, AppStyle.black),
                      ),
                      Text(
                        'ONE',
                        style: getMainTextStyle(context, AppStyle.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
               //   Text(
                 //   'by Juvo Platforms',
               //     style: getSecondaryTextStyle(context),
               //   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
