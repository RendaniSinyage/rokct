import 'dart:async';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_dropdown/models/value_item.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../../../../../models/data/edit_shop_data.dart';
import '../../../../../../models/data/location_data.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../../../../theme/theme.dart';
import 'shop_state.dart';

class ShopNotifier extends StateNotifier<ShopState> {
  String _statusNote = '';
  String _title = '';
  String _description = '';
  String _phone = '';
  String _price = '';
  String _minAmount = '';
  String _perKm = '';
  String _from = '';
  String _to = '';
  String _tax = '';
  String _percentage = '';

  ShopNotifier() : super(const ShopState());
  Timer? timer;

  void setCloseDay(int index) {
    EditShopData? closeDays = state.editShopData;
    ShopWorkingDays? workingDays = closeDays?.shopWorkingDays?[index];
    workingDays =
        workingDays?.copyWith(disabled: !(workingDays.disabled ?? false));
    closeDays?.shopWorkingDays?[index] = workingDays ?? ShopWorkingDays();
    state = state.copyWith(editShopData: closeDays);
  }

  void setUpdate() {
    state = state.copyWith(isLogoImageLoading: true);
    state = state.copyWith(isLogoImageLoading: false);
  }

  void setStatusNote(String value) {
    _statusNote = value.trim();
  }

  void setPhone(String value) {
    _phone = value.trim();
  }

  void setDescription(String value) {
    _description = value.trim();
  }

  void setTitle(String value) {
    _title = value.trim();
  }

  void setPrice(String value) {
    _price = value.trim();
  }

  void setAmount(String value) {
    _minAmount = value.trim();
  }

  void setPerKm(String value) {
    _perKm = value.trim();
  }

  void setFrom(String value) {
    _from = value.trim();
  }

  void setTo(String value) {
    _to = value.trim();
  }

  void setTax(String value) {
    _tax = value.trim();
  }

  void setPercentage(String value) {
    _percentage = value.trim();
  }

  Future<void> fetchShopData(
      {VoidCallback? checkYourNetwork, VoidCallback? onSuccess}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isEditShopData: true);
      final response = await shopsRepository.getShopData();
      await fetchShopTag();
      await fetchShopCategory();
      response.when(
        success: (data) async {
          state = state.copyWith(
              isEditShopData: false, editShopData: data, isUpdate: false);
          onSuccess?.call();
        },
        failure: (failure) {
          state = state.copyWith(isEditShopData: false);
          debugPrint('==> get editShopData failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchShopCategory({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      final response = await shopsRepository.getShopCategory();
      response.when(
        success: (data) async {
          state = state.copyWith(categories: data);
        },
        failure: (failure) {
          debugPrint('==> get editShopCategory failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchShopTag({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      final response = await shopsRepository.getShopTag();
      response.when(
        success: (data) async {
          state = state.copyWith(tag: data);
        },
        failure: (failure) {
          debugPrint('==> get editShopTag failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> updateShopData({
    required VoidCallback onSuccess,
    required LocationData? location,
    String? displayName,
    List<ValueItem>? category,
    List<ValueItem>? tag,
    List<ValueItem>? type,
  }) async {
    state = state.copyWith(isSave: true);
    final response = await shopsRepository.updateShopData(
        displayName: displayName,
        category: category,
        tag: tag,
        type: type,
        editShopData: EditShopData(
            location: Location(
                longitude: location?.longitude.toString(),
                latitude: location?.latitude.toString()),
            status: state.editShopData?.status,
            statusNote: _statusNote.isNotEmpty
                ? _statusNote
                : state.editShopData?.statusNote,
            translation: Translation(
                title: _title.isNotEmpty
                    ? _title
                    : state.editShopData?.translation?.title,
                description: _description.isNotEmpty
                    ? _description
                    : state.editShopData?.translation?.description),
            phone: _phone.isNotEmpty ? _phone : state.editShopData?.phone,
            price: _price.isNotEmpty
                ? num.tryParse(_price)
                : state.editShopData?.price,
            minAmount: _minAmount.isNotEmpty
                ? num.tryParse(_minAmount)
                : state.editShopData?.minAmount,
            perKm: _perKm.isNotEmpty
                ? num.tryParse(_perKm)
                : state.editShopData?.perKm,
            deliveryTime: DeliveryTime(
                from: _from.isNotEmpty
                    ? _from
                    : state.editShopData?.deliveryTime?.from,
                to: _to.isNotEmpty
                    ? _to
                    : state.editShopData?.deliveryTime?.to),
            tax: _tax.isNotEmpty ? num.tryParse(_tax) : state.editShopData?.tax,
            percentage: _percentage.isNotEmpty
                ? num.tryParse(_percentage)
                : state.editShopData?.percentage),
        logoImg: state.logoImageUrl,
        backImg: state.backImageUrl);
    response.when(
      success: (data) {
        state = state.copyWith(isSave: false, isUpdate: true);
        onSuccess.call();
      },
      failure: (fail) {
        state = state.copyWith(isSave: false);
        debugPrint('===> update delivery zone failed $fail');
      },
    );
  }

  Future<void> updateWorkingDays({
    required List<ShopWorkingDays>? days,
    required String shopUuid,
  }) async {
    state = state.copyWith(isSave: true);
    final response = await shopsRepository.updateShopWorkingDays(
      workingDays: days ?? [],
      uuid: shopUuid,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isSave: true);
      },
      failure: (failure) {
        state = state.copyWith(isSave: false);
        debugPrint('==> error update working days $failure');
      },
    );
  }

  Future<void> getPhoto(
      {bool isLogoImage = false, required BuildContext context}) async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Image Cropper',
            toolbarColor: AppStyle.white,
            toolbarWidgetColor: AppStyle.black,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(title: 'Image Cropper', minimumAspectRatio: 1),
        ],
      );
      // ignore: use_build_context_synchronously
      await updateShopImage(context, croppedFile?.path ?? "", isLogoImage);
      state = isLogoImage
          ? state.copyWith(logoImagePath: croppedFile?.path ?? "")
          : state.copyWith(backImagePath: croppedFile?.path ?? "");
    }
  }

  void setSelectedOrderType(String? type) {
    state = state.copyWith(orderType: type ?? state.orderType);
  }

  setNote(String note) {
    state = state.copyWith(comment: note);
  }

  Future<void> updateShopImage(
      BuildContext context, String path, bool isLogoImage) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = isLogoImage
          ? state.copyWith(isLogoImageLoading: true)
          : state.copyWith(isBackImageLoading: true);
      String? url;
      final imageResponse =
          await galleryRepository.uploadImage(path, UploadType.users);
      imageResponse.when(
        success: (data) {
          url = data.imageData?.title;
          state = isLogoImage
              ? state.copyWith(
                  logoImageUrl: url ?? "", isLogoImageLoading: false)
              : state.copyWith(
                  backImageUrl: url ?? "", isBackImageLoading: false);
        },
        failure: (failure) {
          state = isLogoImage
              ? state.copyWith(isLogoImageLoading: false)
              : state.copyWith(isBackImageLoading: false);
          debugPrint('==> upload edit shop image failure: $failure');
          AppHelpers.showSnackBar(
            context,
            AppHelpers.getTranslation(failure.toString()),
          );
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
}

