import 'dart:io';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../../../../../repository/repository.dart';
import '../state/login_state.dart';

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final UsersRepository _usersRepository;
  final CurrenciesRepository _currenciesRepository;

  LoginNotifier(
      this._authRepository, this._currenciesRepository, this._usersRepository)
      : super(const LoginState());

  void setPassword(String text) {
    state = state.copyWith(
      password: text.trim(),
      isLoginError: false,
      isEmailNotValid: false,
      isPasswordNotValid: false,
    );
  }

  void setEmail(String text) {
    state = state.copyWith(
      email: text.trim(),
      isLoginError: false,
      isEmailNotValid: false,
      isPasswordNotValid: false,
    );
  }

  void setShowPassword(bool show) {
    state = state.copyWith(showPassword: show);
  }

  Future<void> login({
    VoidCallback? unAuthorised,
    VoidCallback? goToMain,
    required BuildContext context,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!AppValidators.isValidEmail(state.email)) {
        state = state.copyWith(isEmailNotValid: true);
        return;
      }
      state = state.copyWith(isLoading: true);
      final response = await _authRepository.login(
        email: state.email,
        password: state.password,
      );
      response.when(
        success: (data) async {
          LocalStorage.setToken(data.data?.accessToken ?? '');

          // Save user data
          final userData = data.data?.user;
          await LocalStorage.setUser(userData);

          // Save shop location
          if (userData != null) {
            print('Saving shop location for user: ${userData.id}'); // Debug print
            await LocalStorage.saveUserShopLocation(userData);

            // Debug prints to verify location
            final savedLocation = LocalStorage.getShopLocation();
            print('Saved shop location: lat=${savedLocation?.latitude}, lon=${savedLocation?.longitude}');
          }

          fetchCurrencies(
            checkYourNetworkConnection: () {
              if (context.mounted) {
                AppHelpers.showSnackBar(
                  context,
                  AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
                );
              }
            },
            goToMain: goToMain,
          );

          final res = await _usersRepository.getProfileDetails(context);

          res.when(
              success: (s) {
                LocalStorage.setUser(s.data);
                // Also save shop location after getting profile details
                LocalStorage.saveUserShopLocation(s.data);
              },
              failure: (failure) {});

          if (Platform.isAndroid || Platform.isIOS) {
            String? fcmToken;
            try {
              fcmToken = await FirebaseMessaging.instance.getToken();
            } catch (e) {
              debugPrint('===> error with getting firebase token $e');
            }
            _authRepository.updateFirebaseToken(fcmToken);
          }
        },
        failure: (failure) {
          state = state.copyWith(isLoading: false, isLoginError: true);
          debugPrint('==> login failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }

  Future<void> fetchCurrencies({
    VoidCallback? checkYourNetworkConnection,
    VoidCallback? goToMain,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isCurrenciesLoading: true);
      final response = await _currenciesRepository.getCurrencies();
      response.when(
        success: (data) async {
          int defaultCurrencyIndex = 0;
          final List<CurrencyData> currencies = data.data ?? [];
          for (int i = 0; i < currencies.length; i++) {
            if (currencies[i].isDefault ?? false) {
              defaultCurrencyIndex = i;
              break;
            }
          }
          LocalStorage.setSelectedCurrency(currencies[defaultCurrencyIndex]);
          state = state.copyWith(isCurrenciesLoading: false);
          goToMain?.call();
        },
        failure: (failure) {
          state = state.copyWith(isCurrenciesLoading: false);
          goToMain?.call();
          debugPrint('==> get currency failure: $failure');
        },
      );
    } else {
      checkYourNetworkConnection?.call();
      goToMain?.call();
    }
  }
}

