import 'dart:ui';
import 'dart:io' show Platform;
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../generated/assets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/utils.dart';
import '../../components/components.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'riverpod/provider/splash_provider.dart';
@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration.zero,
      () {
        if(mounted) {
          ref.read(splashProvider.notifier).fetchGlobalSettings(
          context,
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              TrKeys.checkYourNetworkConnection,
            );
          },
        );
	}
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.white,
      body: Stack(
        children: [
          if (!AppConstants.enableJuvoONE)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Image.asset(
                Assets.pngManImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (isDesktop)
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: AppStyle.black,
                onPressed: () async {
                  await windowManager.close();
                },
              ),
            ),
          Center(
            child: AppConstants.enableJuvoONE
                ? const LoadingAnimation()
                : const CircularProgressIndicator(color: AppStyle.black),
          ),
        ],
      ),
    );
  }
}
