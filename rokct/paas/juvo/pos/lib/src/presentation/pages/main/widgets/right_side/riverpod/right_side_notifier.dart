import 'dart:async';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/models/response/product_calculate_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../JuvoONE/components/payment_dialog.dart';
import 'right_side_state.dart';

class RightSideNotifier extends StateNotifier<RightSideState> {
  Timer? _searchUsersTimer;
  Timer? _searchSectionTimer;
  Timer? _searchTableTimer;
  String _phone = '';

  RightSideNotifier() : super(const RightSideState());
  Timer? timer;

  PaymentData _createTerminalPayment() {
    return PaymentData(
      id: -1,
      tag: 'terminal',
      input: 1,
      sandbox: LocalStorage.isYocoTest(),
      active: true,
      translation: Translation(
        title: 'Card Terminal',
        description: 'Pay with card via Yoco terminal',
      ),
    );
  }

  void setCoupon(String coupon, BuildContext context) {
    state = state.copyWith(coupon: coupon, isActive: false);
    fetchCarts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }

  void setCalculate(String item) {
    // Handle backspace
    if (item == "-1" && state.calculate.isNotEmpty) {
      if (state.calculate.length == 1) {
        state = state.copyWith(calculate: "0");
      } else {
        state = state.copyWith(
            calculate: state.calculate.substring(0, state.calculate.length - 1)
        );
      }
      return;
    }

    // Length check
    if (state.calculate.length > 25) {
      return;
    }

    // Handle decimal point
    if (item == ".") {
      if (state.calculate.isEmpty || state.calculate == "0") {
        state = state.copyWith(calculate: "0.");
        return;
      }
      if (state.calculate.contains(".")) {
        return;
      }
    }

    // Handle number input
    if (item != "-1") {
      // If current value is "0" and new input is not decimal point
      if (state.calculate == "0" && item != ".") {
        state = state.copyWith(calculate: item);
      } else {
        state = state.copyWith(calculate: state.calculate + item);
      }
    }
  }

  void clearCalculate() {
    state = state.copyWith(calculate: "0");
  }

  void setUpdate() {
    state = state.copyWith(isLogoImageLoading: true);
    state = state.copyWith(isLogoImageLoading: false);
  }

  Future<void> fetchBags() async {
    state = state.copyWith(isBagsLoading: true, bags: []);
    List<BagData> bags = LocalStorage.getBags();
    if (bags.isEmpty) {
      final BagData firstBag = BagData(index: 0, bagProducts: []);
      LocalStorage.setBags([firstBag]);
      bags = [firstBag];
    }
    state = state.copyWith(
      bags: bags,
      isBagsLoading: false,
      selectedUser: bags[0].selectedUser,
      isActive: false,
      isPromoCodeLoading: false,
      coupon: null,
    );
  }

  Future<void> checkPromoCode(
      BuildContext context,
      String? promoCode,
      ) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isPromoCodeLoading: true, isActive: false);

      final response = await usersRepository.checkCoupon(
        coupon: promoCode ?? "",
        shopId: LocalStorage.getUser()?.role == TrKeys.waiter
            ? LocalStorage.getUser()?.invite?.shopId ?? 0
            : LocalStorage.getUser()?.shop?.id ?? 0,
      );
      response.when(
        success: (data) {
          state = state.copyWith(isPromoCodeLoading: false, isActive: true);
        },
        failure: (failure) {
          state = state.copyWith(
            isPromoCodeLoading: false,
            isActive: false,
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showSnackBar(
            context, AppHelpers.getTranslation(TrKeys.noInternetConnection));
      }
    }
  }

  void addANewBag() {
    List<BagData> newBags = List.from(state.bags);
    newBags.add(BagData(
        index: newBags.length,
        bagProducts: [],
        selectedPayment: state.payments
            .where(
              (element) => element.tag == 'cash',
        )
            .first,
        selectedCurrency: LocalStorage.getSelectedCurrency()));
    LocalStorage.setBags(newBags);
    state = state.copyWith(bags: newBags);
  }

  void setSelectedBagIndex(int index) {
    state = state.copyWith(
      selectedBagIndex: index,
      selectedUser: state.bags[index].selectedUser,
    );
  }

  void removeBag(int index) {
    List<BagData> bags = List.from(state.bags);
    List<BagData> newBags = [];
    bags.removeAt(index);
    for (int i = 0; i < bags.length; i++) {
      newBags.add(BagData(index: i, bagProducts: bags[i].bagProducts));
    }
    LocalStorage.setBags(newBags);
    final int selectedIndex =
    state.selectedBagIndex == index ? 0 : state.selectedBagIndex;
    state = state.copyWith(bags: newBags, selectedBagIndex: selectedIndex);
  }

  void removeOrderedBag(BuildContext context) {
    List<BagData> bags = List.from(state.bags);
    List<BagData> newBags = [];
    bags.removeAt(state.selectedBagIndex);
    if (bags.isEmpty) {
      final BagData firstBag = BagData(index: 0, bagProducts: []);
      newBags = [firstBag];
    } else {
      for (int i = 0; i < bags.length; i++) {
        newBags.add(BagData(index: i, bagProducts: bags[i].bagProducts));
      }
    }
    LocalStorage.setBags(newBags);
    state = state.copyWith(
        bags: newBags,
        selectedBagIndex: 0,
        selectedUser: null,
        selectedAddress: null,
        selectedCurrency: null,
        selectedPayment: null,
        orderType: LocalStorage.getUser()?.role == 'waiter'
            ? TrKeys.dine
            : TrKeys.pickup);
    setInitialBagData(context, newBags[0]);
  }

  Future<void> fetchPayments({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!LocalStorage.hasYocoCredentials()) {
        print('Initializing Yoco credentials');
        await LocalStorage.setYocoKeys(
          publicKey: AppConstants.YOCO_TEST_PUBLIC_KEY,
          privateKey: AppConstants.YOCO_TEST_PRIVATE_KEY,
          isTest: true,
        );
      }

      print('Checking Yoco configuration:');
      print('Has Yoco credentials: ${LocalStorage.hasYocoCredentials()}');
      print('Yoco public key: ${LocalStorage.getYocoPublicKey()}');
      print('Yoco environment: ${LocalStorage.isYocoTest() ? 'test' : 'live'}');

      state = state.copyWith(isPaymentsLoading: true, payments: []);
      final response = await paymentsRepository.getPayments();

      response.when(
        success: (data) async {
          List<PaymentData> allPayments = [];

          if (LocalStorage.hasYocoCredentials()) {
            print('Adding terminal payment to options');
            allPayments.add(_createTerminalPayment());
          }

          if (data.data != null) {
            for (final payment in data.data!) {
              if (payment.tag == 'cash' || payment.tag == 'wallet') {
                allPayments.add(payment);
              }
            }
          }

          print('Final payment methods:');
          for (var payment in allPayments) {
            print('Payment: ${payment.tag} (ID: ${payment.id})');
          }

          state = state.copyWith(
            isPaymentsLoading: false,
            payments: allPayments,
          );
        },
        failure: (failure) {
          state = state.copyWith(isPaymentsLoading: false);
          debugPrint('==> get payments failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchUsers({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(
        isUsersLoading: true,
        dropdownUsers: [],
        users: [],
      );
      final response = await usersRepository.searchUsers(
          query: state.usersQuery.isEmpty ? null : state.usersQuery);
      response.when(
        success: (data) async {
          final List<UserData> users = data.users ?? [];
          List<DropDownItemData> dropdownUsers = [];
          for (int i = 0; i < users.length; i++) {
            dropdownUsers.add(
              DropDownItemData(
                index: i,
                title: '${users[i].firstname} ${users[i].lastname ?? ""}',
              ),
            );
          }
          state = state.copyWith(
            isUsersLoading: false,
            users: users,
            dropdownUsers: dropdownUsers,
          );
        },
        failure: (failure) {
          state = state.copyWith(isUsersLoading: false);
          debugPrint('==> get users failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchSections({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isSectionLoading: true, sections: []);
      final response = await tableRepository.getSection(
          query: state.sectionQuery.isEmpty ? null : state.sectionQuery);
      response.when(
        success: (data) async {
          state = state.copyWith(
            isSectionLoading: false,
            sections: data.data ?? [],
          );
        },
        failure: (failure) {
          state = state.copyWith(isSectionLoading: false);
          debugPrint('==> get sections failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchTables({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isTableLoading: true, tables: []);
      final response = await tableRepository.getTables(
          query: state.tableQuery.isEmpty ? null : state.tableQuery,
          type: TrKeys.available,
          shopSectionId: state.selectedSection?.id);
      response.when(
        success: (data) async {
          state = state.copyWith(
            isTableLoading: false,
            tables: data.data ?? [],
          );
        },
        failure: (failure) {
          state = state.copyWith(isTableLoading: false);
          debugPrint('==> get tables failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setStatusNote(String value) {}

  void setPhone(String value) {
    _phone = value.trim();
  }

  void setUsersQuery(BuildContext context, String query) {
    state = state.copyWith(usersQuery: query.trim());

    if (_searchUsersTimer?.isActive ?? false) {
      _searchUsersTimer?.cancel();
    }
    _searchUsersTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(users: [], dropdownUsers: []);
        fetchUsers(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      },
    );
  }

  void setSectionQuery(BuildContext context, String query) {
    state = state.copyWith(sectionQuery: query.trim());

    if (_searchSectionTimer?.isActive ?? false) {
      _searchSectionTimer?.cancel();
    }
    _searchSectionTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(sections: []);
        fetchSections(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      },
    );
  }

  void setTableQuery(BuildContext context, String query) {
    state = state.copyWith(tableQuery: query.trim());

    if (_searchTableTimer?.isActive ?? false) {
      _searchTableTimer?.cancel();
    }
    _searchTableTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(sections: []);
        fetchTables(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
          },
        );
      },
    );
  }

  void setSelectedUser(BuildContext context, int index) {
    final user = state.users[index];
    final bags = LocalStorage.getBags();
    final bag = bags[state.selectedBagIndex].copyWith(selectedUser: user);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(
      bags: bags,
      selectedUser: user,
      selectUserError: null,
    );
    fetchUserDetails(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
    setUsersQuery(context, '');
  }

  void setSelectedSection(BuildContext context, int index) {
    final section = state.sections[index];
    final bags = LocalStorage.getBags();
    final bag = bags[state.selectedBagIndex].copyWith(selectedSection: section);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(
      bags: bags,
      selectedSection: section,
      selectSectionError: null,
    );
    setSectionQuery(context, '');
  }

  void setSelectedTable(BuildContext context, int index) {
    final table = state.tables[index];
    final bags = LocalStorage.getBags();
    final bag = bags[state.selectedBagIndex].copyWith(selectedTable: table);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(
      bags: bags,
      selectedTable: table,
      selectTableError: null,
    );
    setTableQuery(context, '');
  }

  void removeSelectedUser() {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final BagData bag = bags[state.selectedBagIndex]
        .copyWith(selectedUser: null, selectedAddress: null);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedUser: null);
  }

  void removeSelectedSection() {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final BagData bag =
    bags[state.selectedBagIndex].copyWith(selectedSection: null);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedSection: null);
  }

  void removeSelectedTable() {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final BagData bag =
    bags[state.selectedBagIndex].copyWith(selectedTable: null);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedTable: null);
  }

  Future<void> fetchUserDetails({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isUserDetailsLoading: true);
      final response =
      await usersRepository.getUserDetails(state.selectedUser?.uuid ?? '');
      response.when(
        success: (data) async {
          state = state.copyWith(
            isUserDetailsLoading: false,
            selectedUser: data.data,
          );
        },
        failure: (failure) {
          state = state.copyWith(isUserDetailsLoading: false);
          debugPrint('==> get users details failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setSelectedOrderType(String? type) {
    PaymentData? selectedPayment = state.selectedPayment;
    if (state.selectedPayment?.tag != 'cash') {
      final List<PaymentData> payments = List.from(state.payments);
      selectedPayment = payments.firstWhere((e) => e.tag == 'cash',
          orElse: () => PaymentData());
    }
    state = state.copyWith(
      orderType: type ?? state.orderType,
      selectedPayment: selectedPayment,
      selectPaymentError: null,
      selectUserError: null,
      selectAddressError: null,
      selectCurrencyError: null,
      selectTableError: null,
      selectSectionError: null,
    );
  }

  void setSelectedAddress({AddressData? address}) {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final user = bags[state.selectedBagIndex].selectedUser;
    final BagData bag = bags[state.selectedBagIndex]
        .copyWith(selectedAddress: address, selectedUser: user);
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedAddress: address);
  }

  void setSelectedPayment(int? paymentId) {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final user = bags[state.selectedBagIndex].selectedUser;
    final address = bags[state.selectedBagIndex].selectedAddress;
    PaymentData? paymentData;

    print('Setting payment with ID: $paymentId');
    print('Available payments: ${state.payments.map((p) => '${p.tag}:${p.id}').join(', ')}');

    for (final payment in state.payments) {
      if ((payment.id == paymentId) ||
          (payment.tag == 'terminal' && paymentId == -1)) {
        paymentData = payment;
        break;
      }
    }

    final BagData bag = bags[state.selectedBagIndex].copyWith(
      selectedAddress: address,
      selectedUser: user,
      selectedPayment: paymentData,
    );

    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedPayment: paymentData);
  }

  void setSelectedCurrency(int? currencyId) {
    final List<BagData> bags = List.from(LocalStorage.getBags());
    final user = bags[state.selectedBagIndex].selectedUser;
    final address = bags[state.selectedBagIndex].selectedAddress;
    CurrencyData? currencyData;
    for (final currency in state.currencies) {
      if (currencyId == currency.id) {
        currencyData = currency;
        break;
      }
    }
    final BagData bag = bags[state.selectedBagIndex].copyWith(
      selectedAddress: address,
      selectedUser: user,
      selectedCurrency: currencyData,
    );
    bags[state.selectedBagIndex] = bag;
    LocalStorage.setBags(bags);
    state = state.copyWith(bags: bags, selectedCurrency: currencyData);
    fetchCarts(checkYourNetwork: () {}, isNotLoading: true);
  }

  Future<void> fetchCurrencies({VoidCallback? checkYourNetwork}) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isCurrenciesLoading: true, currencies: []);
      final response = await currenciesRepository.getCurrencies();
      response.when(
        success: (data) async {
          state = state.copyWith(
            isCurrenciesLoading: false,
            currencies: data.data ?? [],
          );
        },
        failure: (failure) {
          state = state.copyWith(isCurrenciesLoading: false);
          debugPrint('==> get currencies failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setInitialBagData(BuildContext context, BagData bag) {
    state = state.copyWith(
      selectedAddress: bag.selectedAddress,
      selectedUser: bag.selectedUser,
      selectedCurrency: bag.selectedCurrency,
      selectedPayment: bag.selectedPayment,
      orderType: state.orderType.isEmpty
          ? LocalStorage.getUser()?.role == 'waiter'
          ? TrKeys.dine
          : TrKeys.pickup
          : state.orderType,
    );
    if (bag.selectedUser != null) {
      fetchUserDetails(
        checkYourNetwork: () {
          AppHelpers.showSnackBar(
            context,
            AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
          );
        },
      );
    }
    fetchCarts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }

  bool _validateOrderInputs() {
    bool active = true;

    if (state.orderType == TrKeys.dine) {
      if (state.selectedSection == null) {
        active = false;
        state = state.copyWith(selectSectionError: TrKeys.selectSection);
      }
      if (state.selectedTable == null) {
        active = false;
        state = state.copyWith(selectTableError: TrKeys.selectTable);
      }
    }

    if (state.orderType == TrKeys.delivery) {
      if (state.selectedUser == null) {
        active = false;
        state = state.copyWith(selectUserError: TrKeys.selectUser);
      }
      if (state.selectedAddress == null) {
        active = false;
        state = state.copyWith(selectAddressError: TrKeys.selectAddress);
      }
    }

    if (state.selectedCurrency == null) {
      active = false;
      state = state.copyWith(selectCurrencyError: TrKeys.selectCurrency);
    }

    if (state.selectedPayment == null) {
      active = false;
      state = state.copyWith(selectPaymentError: TrKeys.selectPayment);
    }

    return active;
  }

  Future<void> placeOrder({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? openSelectDeliveriesDrawer,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!_validateOrderInputs()) {
        return;
      }

      if (state.selectedPayment?.tag == 'terminal') {
        if (!LocalStorage.hasYocoCredentials()) {
          state = state.copyWith(
            selectPaymentError: 'Terminal not configured',
          );
          return;
        }

        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => YocoTerminalDialog(
            amount: state.paginateResponse?.totalPrice ?? 0,
            currency: state.selectedCurrency?.title ?? 'ZAR',
            onComplete: (success, transactionId) {
              Navigator.of(context)
                  .pop({'success': success, 'transactionId': transactionId});
            },
          ),
        );

        if (result == null || result['success'] != true) {
          return;
        }

        state = state.copyWith(
          terminalTransactionId: result['transactionId'],
        );
      }

      if (state.orderType != TrKeys.delivery) {
        openSelectDeliveriesDrawer?.call();
      } else {
        if (state.selectedUser?.phone?.isEmpty ?? true) {
          state = state.copyWith(
            selectedUser: state.selectedUser?.copyWith(phone: _phone),
          );
        }
        openSelectDeliveriesDrawer?.call();
      }
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> createOrder(
      BuildContext context,
      OrderBodyData data, {
        VoidCallback? onSuccess,
      }) async {
    final connected = await AppConnectivity.connectivity();
    if (!connected) {
      if (context.mounted) {
        AppHelpers.showSnackBar(
            context,
            AppHelpers.getTranslation(TrKeys.noInternetConnection)
        );
      }
      return;
    }

    if (!_validateOrderInputs()) {
      return;
    }

    state = state.copyWith(isOrderLoading: true);

    // Handle wallet payments
    if (data.bagData.selectedPayment?.tag == "wallet") {
      final num wallet = state.selectedUser?.wallet?.price ?? 0;
      if (wallet < (state.paginateResponse?.totalPrice ?? 0)) {
        if (context.mounted) {
          AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.notEnoughMoney)
          );
        }
        state = state.copyWith(isOrderLoading: false);
        return;
      }
    }

    // Handle terminal payments
    if (data.bagData.selectedPayment?.tag == 'terminal') {
      if (!LocalStorage.hasYocoCredentials()) {
        state = state.copyWith(
          selectPaymentError: 'Terminal not configured',
          isOrderLoading: false,
        );
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => YocoTerminalDialog(
          amount: state.paginateResponse?.totalPrice ?? 0,
          currency: state.selectedCurrency?.title ?? 'ZAR',
          onComplete: (success, transactionId) {
            Navigator.of(context).pop({
              'success': success,
              'transactionId': transactionId
            });
          },
        ),
      );

      if (result == null || result['success'] != true) {
        state = state.copyWith(isOrderLoading: false);
        return;
      }

      state = state.copyWith(
        terminalTransactionId: result['transactionId'],
      );
    }

    try {
      // Create order
      final response = await ordersRepository.createOrder(data);

      if (!context.mounted) return;

      await response.when(
        success: (res) async {
          if (res.data?.id == null) {
            throw Exception('Order ID is null');
          }

          try {
            // Create transaction
            await paymentsRepository.createTransaction(
              orderId: res.data!.id!,
              paymentId: data.bagData.selectedPayment?.id ?? 0,
              terminalTransactionId: data.bagData.selectedPayment?.tag == 'terminal'
                  ? state.terminalTransactionId
                  : null,
            );

            if (!context.mounted) return;

            // Handle auto-deliver if enabled
            if (AppConstants.autoDeliver) {
              try {
                await ordersRepository.updateOrderStatus(
                  orderId: res.data!.id!,
                  status: OrderStatus.delivered,
                );
              } catch (e) {
                debugPrint('Auto-deliver update error: $e');
              }
            }

            state = state.copyWith(isOrderLoading: false);
            onSuccess?.call();

            // Delay bag removal slightly to ensure proper state updates
            Future.microtask(() {
              if (context.mounted) {
                removeOrderedBag(context);
              }
            });

          } catch (e) {
            debugPrint('Transaction error (but continuing): $e');
            // Continue even if transaction has error since it's recorded

            state = state.copyWith(isOrderLoading: false);
            onSuccess?.call();

            if (context.mounted) {
              removeOrderedBag(context);
            }
          }
        },
        failure: (failure) {
          state = state.copyWith(isOrderLoading: false);
          if (context.mounted) {
            AppHelpers.showSnackBar(context, failure.toString());
          }
        },
      );

    } catch (e) {
      debugPrint('Error in order/transaction process: $e');
      state = state.copyWith(isOrderLoading: false);
      if (context.mounted) {
        AppHelpers.showSnackBar(
            context,
            AppHelpers.getTranslation(TrKeys.orderProcessingError)
        );
      }
    }
  }

  void setNote(String note) {
    state = state.copyWith(comment: note);
  }

  void clearBag() {
    var newPagination = state.paginateResponse?.copyWith(stocks: []);
    state = state.copyWith(paginateResponse: newPagination);
    List<BagData> bags = List.from(LocalStorage.getBags());
    bags[state.selectedBagIndex] =
        bags[state.selectedBagIndex].copyWith(bagProducts: []);
    LocalStorage.setBags(bags);
  }

  void deleteProductFromBag(BuildContext context, BagProductData bagProduct) {
    final List<BagProductData> bagProducts =
    List.from(LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? []);
    int index = 0;
    for (int i = 0; i < bagProducts.length; i++) {
      if (bagProducts[i].stockId == bagProduct.stockId) {
        index = i;
        break;
      }
    }
    bagProducts.removeAt(index);
    List<BagData> bags = List.from(LocalStorage.getBags());
    bags[state.selectedBagIndex] =
        bags[state.selectedBagIndex].copyWith(bagProducts: bagProducts);
    LocalStorage.setBags(bags);
    fetchCarts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }

  void deleteProductCount({
    required BagProductData? bagProductData,
    required int productIndex,
  }) {
    List<ProductData>? listOfProduct = state.paginateResponse?.stocks;
    listOfProduct?.removeAt(productIndex);
    PriceDate? data = state.paginateResponse;
    PriceDate? newData = data?.copyWith(stocks: listOfProduct);
    state = state.copyWith(paginateResponse: newData);
    final List<BagProductData> bagProducts =
        LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? [];
    bagProducts.removeAt(productIndex);

    List<BagData> bags = List.from(LocalStorage.getBags());
    bags[state.selectedBagIndex] =
        bags[state.selectedBagIndex].copyWith(bagProducts: bagProducts);
    LocalStorage.setBags(bags);

    fetchCarts(isNotLoading: true);
  }

  Future<void> decreaseProductCount({required int productIndex}) async {
    timer?.cancel();
    ProductData? product = state.paginateResponse?.stocks?[productIndex];

    if ((product?.quantity ?? 1) > 1) {
      ProductData? newProduct = product?.copyWith(
        quantity: ((product.quantity ?? 0) - 1),
      );
      if (newProduct?.quantity == 0) {
        clearBag();
      }
      List<ProductData>? listOfProduct = state.paginateResponse?.stocks;
      listOfProduct?.removeAt(productIndex);
      listOfProduct?.insert(productIndex, newProduct ?? ProductData());
      PriceDate? data = state.paginateResponse;
      PriceDate? newData = data?.copyWith(stocks: listOfProduct);
      state = state.copyWith(paginateResponse: newData);
      final List<BagProductData> bagProducts =
          LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? [];
      BagProductData newProductData = bagProducts[productIndex]
          .copyWith(quantity: (bagProducts[productIndex].quantity ?? 0) - 1);
      bagProducts.removeAt(productIndex);
      bagProducts.insert(productIndex, newProductData);

      List<BagData> bags = List.from(LocalStorage.getBags());
      bags[state.selectedBagIndex] =
          bags[state.selectedBagIndex].copyWith(bagProducts: bagProducts);
      LocalStorage.setBags(bags);
    } else {
      List<ProductData>? listOfProduct = state.paginateResponse?.stocks;
      listOfProduct?.removeAt(productIndex);
      PriceDate? data = state.paginateResponse;
      PriceDate? newData = data?.copyWith(stocks: listOfProduct);
      state = state.copyWith(paginateResponse: newData);
      final List<BagProductData> bagProducts =
          LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? [];
      for (int i = 0; i < bagProducts.length; i++) {
        if (bagProducts[i].stockId == product?.stock?.id) {
          bagProducts.removeAt(i);
          if (bagProducts.isNotEmpty) {
            final response = await productsRepository.getAllCalculations(
                bagProducts, state.orderType,
                coupon: state.coupon);

            response.when(
              success: (data) {},
              failure: (error) {
                clearBag();
              },
            );
          } else {
            clearBag();
          }
          break;
        }
      }

      List<BagData> bags = List.from(LocalStorage.getBags());
      bags[state.selectedBagIndex] =
          bags[state.selectedBagIndex].copyWith(bagProducts: bagProducts);
      LocalStorage.setBags(bags);
    }
    timer = Timer(
      const Duration(milliseconds: 500),
          () => fetchCarts(isNotLoading: true),
    );
  }

  void increaseProductCount({required int productIndex}) {
    timer?.cancel();
    ProductData? product = state.paginateResponse?.stocks?[productIndex];
    ProductData? newProduct = product?.copyWith(
      quantity: ((product.quantity ?? 0) + 1),
    );
    List<ProductData>? listOfProduct = state.paginateResponse?.stocks;
    listOfProduct?.removeAt(productIndex);
    listOfProduct?.insert(productIndex, newProduct ?? ProductData());
    PriceDate? data = state.paginateResponse;
    PriceDate? newData = data?.copyWith(stocks: listOfProduct);
    state = state.copyWith(paginateResponse: newData);
    final List<BagProductData> bagProducts =
        LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? [];

    BagProductData newProductData = bagProducts[productIndex]
        .copyWith(quantity: (bagProducts[productIndex].quantity ?? 0) + 1);
    bagProducts.removeAt(productIndex);
    bagProducts.insert(productIndex, newProductData);

    List<BagData> bags = List.from(LocalStorage.getBags());
    bags[state.selectedBagIndex] =
        bags[state.selectedBagIndex].copyWith(bagProducts: bagProducts);
    LocalStorage.setBags(bags);
    timer = Timer(
      const Duration(milliseconds: 500),
          () => fetchCarts(isNotLoading: true),
    );
  }

  Future<void> fetchCarts({
    VoidCallback? checkYourNetwork,
    bool isNotLoading = false,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (isNotLoading) {
        state = state.copyWith(isButtonLoading: true);
      } else {
        state = state.copyWith(
          isProductCalculateLoading: true,
          paginateResponse: null,
          bags: LocalStorage.getBags(),
        );
      }

      final List<BagProductData> bagProducts =
          LocalStorage.getBags()[state.selectedBagIndex].bagProducts ?? [];
      if (bagProducts.isNotEmpty) {
        final response = await productsRepository.getAllCalculations(
          bagProducts,
          state.orderType,
          coupon: state.coupon,
        );

        response.when(
          success: (data) async {
            state = state.copyWith(
              isButtonLoading: false,
              isProductCalculateLoading: false,
              paginateResponse: data.data?.data,
            );
          },
          failure: (failure) {
            state = state.copyWith(
              isProductCalculateLoading: false,
              isButtonLoading: false,
            );
            debugPrint('==> get product calculate failure: $failure');
          },
        );
      }

      state = state.copyWith(
        isButtonLoading: false,
        isProductCalculateLoading: false,
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setDate(DateTime date) {
    state = state.copyWith(orderDate: date);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(orderTime: time);
  }

  @override
  void dispose() {
    _searchUsersTimer?.cancel();
    _searchSectionTimer?.cancel();
    _searchTableTimer?.cancel();
    timer?.cancel();
    super.dispose();
  }
}
