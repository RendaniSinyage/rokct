import 'dart:io';
import 'dart:ui';
import 'package:admin_desktop/src/presentation/components/custom_checkbox.dart';
import 'package:admin_desktop/src/presentation/pages/auth/login/widgets/custom_passwords.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../../generated/assets.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/utils/utils.dart';
import '../../../components/components.dart';
import '../../../theme/app_style.dart';
import 'riverpod/provider/login_provider.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController login = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(loginProvider.notifier);
    final state = ref.watch(loginProvider);
    return KeyboardDismisser(
      child: AbsorbPointer(
        absorbing: state.isLoading,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Blurred background image
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Image.asset(
                  Assets.pngManImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Overlay to darken the background slightly
              Container(
                color: AppStyle.black.withOpacity(0.3),
              ),
              // Close button for desktop
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
              // Centered form
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500.r),
                    padding:
                    EdgeInsets.symmetric(horizontal: 50.r, vertical: 42.r),
                    decoration: BoxDecoration(
                      color: AppStyle.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppStyle.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              Assets.pngAppLogo,
                              height: 40,
                              width: 40,
                            ),
                            5.horizontalSpace,
                            Expanded(
                              child: Center(
                                child: Text(
                                  AppHelpers.getAppName() ?? "Juvo Platforms",
                                  style: GoogleFonts.inter(
                                      fontSize: 32.sp,
                                      color: AppStyle.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        36.verticalSpace,
                        CustomTextField(
                          hintText: AppHelpers.getTranslation(TrKeys.enteruser),
                          onChanged: notifier.setEmail,
                          textController: login,
                          inputType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          isError: state.isLoginError || state.isEmailNotValid,
                          descriptionText: state.isEmailNotValid
                              ? AppHelpers.getTranslation(
                              TrKeys.emailIsNotValid)
                              : (state.isLoginError
                              ? AppHelpers.getTranslation(
                              TrKeys.loginCredentialsAreNotValid)
                              : null),
                          onFieldSubmitted: (value) => notifier.login(
                            context: context,
                            goToMain: () {
                              context.replaceRoute(const MainRoute());
                            },
                          ),
                        ),
                        24.verticalSpace,
                        CustomTextField(
                          textController: password,
                          hintText:
                          AppHelpers.getTranslation(TrKeys.enterpassword),
                          obscure: state.showPassword,
                          onChanged: notifier.setPassword,
                          textCapitalization: TextCapitalization.none,
                          isError:
                          state.isLoginError || state.isPasswordNotValid,
                          descriptionText: state.isPasswordNotValid
                              ? AppHelpers.getTranslation(TrKeys
                              .passwordShouldContainMinimum8Characters)
                              : (state.isLoginError
                              ? AppHelpers.getTranslation(
                              TrKeys.loginCredentialsAreNotValid)
                              : null),
                          suffixIcon: IconButton(
                            splashRadius: 25.r,
                            icon: Icon(
                              state.showPassword
                                  ? FlutterRemix.eye_line
                                  : FlutterRemix.eye_close_line,
                              color: AppStyle.black,
                              size: 20.r,
                            ),
                            onPressed: () =>
                                notifier.setShowPassword(!state.showPassword),
                          ),
                          onFieldSubmitted: (value) => notifier.login(
                            context: context,
                            goToMain: () {
                              bool checkPin = LocalStorage.getPinCode().isEmpty;
                              context.replaceRoute(
                                  PinCodeRoute(isNewPassword: checkPin));
                            },
                          ),
                        ),
                        24.verticalSpace,
                        Row(
                          children: [
                            CustomCheckbox(isActive: true, onTap: () {}),
                            14.horizontalSpace,
                            Text(
                              AppHelpers.getTranslation(TrKeys.keepMe),
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: AppStyle.black,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        36.verticalSpace,
                        LoginButton(
                          isLoading: state.isLoading,
                          title: AppHelpers.getTranslation(TrKeys.login),
                          onPressed: () => notifier.login(
                            context: context,
                            goToMain: () {
                              context.replaceRoute(
                                  PinCodeRoute(isNewPassword: true));
                            },
                          ),
                        ),
                        if (AppConstants.isDemo) ...[
                          36.verticalSpace,
                          CustomPasswords(
                            type: TrKeys.seller,
                            onTap: () {
                              login.text = AppConstants.demoSellerLogin;
                              password.text = AppConstants.demoSellerPassword;
                              notifier.setEmail(AppConstants.demoSellerLogin);
                              notifier
                                  .setPassword(AppConstants.demoSellerPassword);
                            },
                          ),
                          16.verticalSpace,
                          CustomPasswords(
                            type: TrKeys.cooker,
                            onTap: () {
                              login.text = AppConstants.demoCookerLogin;
                              password.text = AppConstants.demoCookerPassword;
                              notifier.setEmail(AppConstants.demoCookerLogin);
                              notifier
                                  .setPassword(AppConstants.demoCookerPassword);
                            },
                          ),
                          16.verticalSpace,
                          CustomPasswords(
                            type: TrKeys.waiter,
                            onTap: () {
                              login.text = AppConstants.demoWaiterLogin;
                              password.text = AppConstants.demoWaiterPassword;
                              notifier.setEmail(AppConstants.demoWaiterLogin);
                              notifier
                                  .setPassword(AppConstants.demoWaiterPassword);
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
      ),
    );
  }
}
