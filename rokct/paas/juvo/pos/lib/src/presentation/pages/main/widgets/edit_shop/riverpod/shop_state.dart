import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../models/data/edit_shop_data.dart';
import 'package:admin_desktop/src/models/models.dart';

part 'shop_state.freezed.dart';

@freezed
class ShopState with _$ShopState {
  const factory ShopState({
    @Default(false) bool isBagsLoading,
    @Default(true) bool isEditShopData,
    @Default(false) bool isSave,
    @Default(true) bool isUpdate,
    @Default(false) bool isButtonLoading,
    @Default(false) bool isActive,
    @Default(false) bool isLogoImageLoading,
    @Default(false) bool isBackImageLoading,
    @Default([]) List<UserData> users,
    @Default([]) List<AddressData> userAddresses,
    @Default(-1) int selectedCloseDay,
    @Default(0) double shopTax,
    @Default('') String usersQuery,
    @Default('') String tableQuery,
    @Default('') String sectionQuery,
    @Default('') String orderType,
    @Default('') String calculate,
    @Default('') String comment,
    @Default('') String logoImagePath,
    @Default('') String logoImageUrl,
    @Default('') String backImagePath,
    @Default('') String backImageUrl,
    @Default(null) CategoriesPaginateResponse? categories,
    @Default(null) CategoriesPaginateResponse? tag,
    EditShopData? editShopData,
    AddressData? selectedAddress,
  }) = _ShopState;

  const ShopState._();
}

