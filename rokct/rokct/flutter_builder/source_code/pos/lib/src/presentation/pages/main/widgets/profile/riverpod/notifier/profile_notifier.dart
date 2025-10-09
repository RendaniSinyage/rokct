// ignore_for_file: unused_field
import 'package:admin_desktop/src/models/models.dart';
import 'package:admin_desktop/src/repository/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/utils/app_connectivity.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import '../state/profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  final UsersRepository _userRepository;
  final ShopsRepository _shopsRepository;
  final GalleryRepositoryFacade _galleryRepository;

  ProfileNotifier(
      this._userRepository, this._galleryRepository, this._shopsRepository)
      : super(const ProfileState());
  int page = 1;

  resetShopData() {
    state = state.copyWith(
        bgImage: "", logoImage: "", addressModel: null, isSaveLoading: false);
  }

  setBgImage(String bgImage) {
    state = state.copyWith(bgImage: bgImage);
  }

  setLogoImage(String logoImage) {
    state = state.copyWith(logoImage: logoImage);
  }

  setAddress(dynamic data) {
    state = state.copyWith(addressModel: data);
  }

  void setUser(UserData user) async {
    state = state.copyWith(userData: user);
  }

  Future<void> fetchUser(BuildContext context) async {
    if (LocalStorage.getToken().isNotEmpty) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        state = state.copyWith(isLoading: true);

        // ignore: use_build_context_synchronously
        final response = await _userRepository.getProfileDetails(context);
        response.when(
          success: (data) async {
            LocalStorage.setUser(data.data);
            state = state.copyWith(isLoading: false, userData: data.data);
          },
          failure: (failure) {
            state = state.copyWith(isLoading: false);
            AppHelpers.showSnackBar(context, failure);
          },
        );
      } else {
        if (mounted) {
          // AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  void logOut() {
    // LocalStorage.logout();
  }

// Future<void> deleteAccount(BuildContext context) async {
//   final connected = await AppConnectivity.connectivity();
//   if (connected) {
//     state = state.copyWith(isLoading: true);
//     final response = await _userRepository.deleteAccount();
//     response.when(
//       success: (data) async {
//         context.router.popUntilRoot();
//         context.replaceRoute(const LoginRoute());
//       },
//       failure: (activeFailure, status) {
//         state = state.copyWith(isLoading: false);
//         AppHelpers.showSnackBar(
//           context,
//           AppHelpers.getTranslation(status.toString()),
//         );
//       },
//     );
//   } else {
//     if (mounted) {
//       AppHelpers.showSnackBar(context, 'No internet connection');
//     }
//   }
// }
}

