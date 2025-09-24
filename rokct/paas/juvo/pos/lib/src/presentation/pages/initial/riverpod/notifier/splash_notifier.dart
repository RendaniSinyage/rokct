import 'package:admin_desktop/src/core/routes/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../../../../repository/repository.dart';
import '../state/splash_state.dart';

class SplashNotifier extends StateNotifier<SplashState> {
  final SettingsRepository _settingsRepository;

  SplashNotifier(this._settingsRepository) : super(const SplashState());

  Future<void> fetchGlobalSettings(
    BuildContext context, {
    VoidCallback? checkYourNetwork,
  }) async {
    if (LocalStorage.getLanguage()?.locale != null) {
      final connect = await AppConnectivity.connectivity();
      if (connect) {
        final response = await _settingsRepository.getGlobalSettings();
        response.when(
          success: (data) async {
            await LocalStorage.setSettingsList(data.data ?? []);
            await LocalStorage
                .setActiveLocale(AppHelpers.getInitialLocale());
            getTranslations(
              goLogin: () {
                context.replaceRoute(const LoginRoute());
              },
              goMain: () {
                bool checkPin = LocalStorage.getPinCode().isEmpty;
                context.replaceRoute(PinCodeRoute(isNewPassword: checkPin));
              },
            );
          },
          failure: (failure) {
            debugPrint('==> error with settings fetched');
            getTranslations(
              goLogin: () {
                context.replaceRoute(const LoginRoute());
              },
              goMain: () {
                bool checkPin = LocalStorage.getPinCode().isEmpty;
                context.replaceRoute(PinCodeRoute(isNewPassword: checkPin));
              },
            );
          },
        );
      } else {
        debugPrint('==> get active languages no connection');
        checkYourNetwork?.call();
      }
    } else {
      getTranslations(
        goLogin: () {
          context.replaceRoute(const LoginRoute());
        },
        goMain: () {
          bool checkPin = LocalStorage.getPinCode().isEmpty;
          context.replaceRoute(PinCodeRoute(isNewPassword: checkPin));
        },
      );
    }
  }

  Future<void> getTranslations({
    VoidCallback? goMain,
    VoidCallback? goLogin,
  }) async {
    final response = await _settingsRepository.getTranslations();
    response.when(
      success: (data) async {
        await LocalStorage.setTranslations(data.data);
        if (LocalStorage.getToken().isEmpty) {
          goLogin?.call();
        } else {
          goMain?.call();
        }
      },
      failure: (failure) {
        debugPrint('==> error with fetching translations $failure');
        if (LocalStorage.getToken().isEmpty) {
          goLogin?.call();
        } else {
          goMain?.call();
        }
      },
    );
  }
}

