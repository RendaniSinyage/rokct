// ignore_for_file: unrelated_type_equality_checks

import 'dart:ui';
import 'dart:io' show Platform;
import 'package:admin_desktop/generated/assets.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/routes/app_router.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/presentation/components/login_button.dart';
import 'package:admin_desktop/src/presentation/pages/auth/pin_code/riverpod/provider/pin_code_provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../theme/app_style.dart';
import 'components/pin_button.dart';
import 'components/pin_container.dart';

@RoutePage()
class PinCodePage extends ConsumerStatefulWidget {
  final bool isNewPassword;

  const PinCodePage(this.isNewPassword, {super.key});

  @override
  ConsumerState<PinCodePage> createState() => _PinCodePageState();
}

class _PinCodePageState extends ConsumerState<PinCodePage> {
  final FocusNode _focusNode = FocusNode();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AppConstants.skipPin) {
        context.replaceRoute(const MainRoute());
      } else {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void handlePinCodeInput(String input) {
    final notifier = ref.read(pinCodeProvider.notifier);
    if (input == 'backspace') {
      notifier.removePinCode();
    } else if (input == 'clear') {
      notifier.clearPinCode();
    } else if (input.length == 1 && int.tryParse(input) != null) {
      if (widget.isNewPassword) {
        notifier.setNewPinCode(
          code: input,
          onSuccess: () {
            context.replaceRoute(const MainRoute());
          },
        );
      } else {
        notifier.setPinCode(
          code: input,
          onSuccess: () {
            context.replaceRoute(const MainRoute());
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppConstants.skipPin) {
      return const SizedBox.shrink();  // Return an empty widget if skipping PIN
    }

    final state = ref.watch(pinCodeProvider);

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            handlePinCodeInput('backspace');
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            handlePinCodeInput('clear');
          } else if (event.character != null &&
              int.tryParse(event.character!) != null) {
            handlePinCodeInput(event.character!);
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
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
              child: Container(
                constraints: BoxConstraints(maxWidth: 500.r),
                padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 32.r),
                decoration: BoxDecoration(
                  color: AppStyle.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppHelpers.getTranslation(widget.isNewPassword
                            ? TrKeys.enterNewPinCode
                            : state.isPinCodeNotValid == false
                            ? TrKeys.enterPinCode
                            : TrKeys.enterPinCodeError),
                        style: GoogleFonts.inter(
                          color: state.isPinCodeNotValid == false
                              ? AppStyle.black
                              : AppStyle.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 28.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      12.r.verticalSpace,
                      Text(
                        AppHelpers.getTranslation(
                            state.isPinCodeNotValid == false
                                ? TrKeys.pinCodeDesc
                                : TrKeys.pinCodeDescError),
                        style: GoogleFonts.inter(
                          color: state.isPinCodeNotValid == false
                              ? AppStyle.black
                              : AppStyle.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                      28.r.verticalSpace,
                      SizedBox(
                        height: 28.r,
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return PinContainer(
                              isActive: state.pinCode.length > index,
                            );
                          },
                        ),
                      ),
                      GridView.builder(
                        padding: EdgeInsets.symmetric(
                          vertical: 24.r,
                          horizontal: 68.r,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 28.r,
                          mainAxisSpacing: 24.r,
                          mainAxisExtent: 72.r,
                        ),
                        itemBuilder: (context, index) {
                          return PinButton(
                            title: index != 9 && index != 11
                                ? AppHelpers.getPinCodeText(index)
                                : null,
                            iconData: index == 9
                                ? FlutterRemix.close_circle_line
                                : index == 11
                                ? FlutterRemix.delete_back_2_line
                                : null,
                            onTap: () {
                              if (index == 9) {
                                handlePinCodeInput('clear');
                              } else if (index == 11) {
                                handlePinCodeInput('backspace');
                              } else {
                                handlePinCodeInput(
                                    AppHelpers.getPinCodeText(index));
                              }
                            },
                          );
                        },
                      ),
                      24.r.verticalSpace,
                      LoginButton(
                        title: AppHelpers.getTranslation(
                          widget.isNewPassword ? TrKeys.save : TrKeys.apply,
                        ),
                        onPressed: () {
                          final notifier = ref.read(pinCodeProvider.notifier);
                          if (widget.isNewPassword) {
                            notifier.checkNewCode(onSuccess: () {
                              context.replaceRoute(const MainRoute());
                            });
                          } else {
                            notifier.checkCode(onSuccess: () {
                              context.replaceRoute(const MainRoute());
                            });
                          }
                        },
                      ),
                      if (!widget.isNewPassword) ...[
                        16.r.verticalSpace,
                        LoginButton(
                          bgColor: AppStyle.transparent,
                          title: AppHelpers.getTranslation(TrKeys.logout),
                          onPressed: () {
                            context.replaceRoute(const LoginRoute());
                            LocalStorage.clearStore();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
