import 'dart:async';
import 'dart:convert';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/models/response/product_calculate_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../../models/models.dart';
import '../../../../../repository/repository.dart';
import '../state/main_state.dart';

class MainNotifier extends StateNotifier<MainState> {
  final ProductsRepository _productsRepository;
  final CategoriesRepository _categoriesRepository;
  final BrandsRepository _brandsRepository;
  final UsersRepository _usersRepository;

  Timer? _searchProductsTimer;
  Timer? _searchCategoriesTimer;
  Timer? _searchBrandsTimer;
  int _page = 0;

  MainNotifier(
      this._productsRepository,
      this._categoriesRepository,
      this._brandsRepository,
      this._usersRepository,
      ) : super(const MainState());

  changeIndex(int index) {
    state = state.copyWith(selectIndex: index);
  }

  setOrder(OrderData? order) {
    state = state.copyWith(selectedOrder: order);
  }

  setPriceDate(PriceDate? priceDate) {
    state = state.copyWith(priceDate: priceDate);
  }

  Future<void> fetchUserDetail(BuildContext context) async {
    final response = await _usersRepository.getProfileDetails(context);
    response.when(
      success: (data) async {
        LocalStorage.setUser(data.data);
      },
      failure: (failure) {
        debugPrint('==> get user detail failure: $failure');
      },
    );
  }

  void updateProductStock(String uuid, Stocks updatedStock) {
    final updatedProducts = state.products.map((product) {
      if (product.uuid == uuid) {
        // Update the stock of this product
        if (product.stocks != null && product.stocks!.isNotEmpty) {
          final updatedStocks = [...product.stocks!];
          final stockIndex = updatedStocks.indexWhere((s) => s.id == updatedStock.id);
          if (stockIndex != -1) {
            updatedStocks[stockIndex] = updatedStock;
          }
          return product.copyWith(stocks: updatedStocks);
        }
      }
      return product;
    }).toList();

    state = state.copyWith(products: updatedProducts);
  }

  Future<void> fetchProducts({
    VoidCallback? checkYourNetwork,
    bool? isRefresh,
  }) async {
    if (isRefresh ?? false) {
      _page = 0;
    } else if (!state.hasMore) {
      return;
    }

    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (_page == 0) {
        state = state.copyWith(isProductsLoading: true, products: []);

        final response = await _productsRepository.getProductsPaginate(
          page: ++_page,
          query: state.query.isEmpty ? null : state.query,
          shopId: state.selectedShop?.id,
          categoryId: state.selectedCategory?.id,
          brandId: state.selectedBrand?.id,
        );

        response.when(
          success: (data) {
            state = state.copyWith(
              products: data.data ?? [],
              isProductsLoading: false,
              hasMore: (data.data?.length ?? 0) >= 12,
            );

            if (state.query.isEmpty &&
                state.selectedCategory == null &&
                state.selectedBrand == null) {
              _saveLocalProducts(data.data ?? []);
            }
          },
          failure: (failure) {
            state = state.copyWith(
              isProductsLoading: false,
              products: [],
            );
            debugPrint('==> get products failure: $failure');
          },
        );
      } else {
        state = state.copyWith(isMoreProductsLoading: true);

        final response = await _productsRepository.getProductsPaginate(
          page: ++_page,
          query: state.query.isEmpty ? null : state.query,
          shopId: state.selectedShop?.id,
          categoryId: state.selectedCategory?.id,
          brandId: state.selectedBrand?.id,
        );

        response.when(
          success: (data) {
            final List<ProductData> newList = List.from(state.products);
            newList.addAll(data.data ?? []);

            state = state.copyWith(
              products: newList,
              isMoreProductsLoading: false,
              hasMore: (data.data?.length ?? 0) >= 12,
            );
          },
          failure: (failure) {
            state = state.copyWith(isMoreProductsLoading: false);
            debugPrint('==> get products more failure: $failure');
          },
        );
      }
    } else {
      if (_page == 0 && state.products.isEmpty) {
        final localProducts = await _loadLocalProducts();
        if (localProducts.isNotEmpty) {
          state = state.copyWith(
            products: localProducts,
            isProductsLoading: false,
            hasMore: false,
          );
        } else {
          state = state.copyWith(
            isProductsLoading: false,
            products: [],
          );
        }
      }
      checkYourNetwork?.call();
    }
  }

  void setProductsQuery(BuildContext context, String query) {
    if (state.query == query) {
      return;
    }

    state = state.copyWith(query: query.trim());

    if (_searchProductsTimer?.isActive ?? false) {
      _searchProductsTimer?.cancel();
    }

    _searchProductsTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(
          hasMore: true,
          products: [],
          isProductsLoading: true,
        );
        _page = 0;
        fetchProducts(
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

  void clearSearch(BuildContext context) {
    if (_searchProductsTimer?.isActive ?? false) {
      _searchProductsTimer?.cancel();
    }

    state = state.copyWith(
      query: '',
      hasMore: true,
      products: [],
      isProductsLoading: true,
    );

    _page = 0;
    fetchProducts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }

  Future<void> fetchCategories({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(
        isCategoriesLoading: true,
        dropDownCategories: [],
        categories: [],
      );
      final response = await _categoriesRepository.searchCategories(
        state.categoryQuery.isEmpty ? null : state.categoryQuery,
      );
      response.when(
        success: (data) async {
          final List<CategoryData> categories = data.data ?? [];
          state = state.copyWith(
            isCategoriesLoading: false,
            categories: categories,
          );
        },
        failure: (failure) {
          state = state.copyWith(isCategoriesLoading: false);
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setCategoriesQuery(BuildContext context, String query) {
    if (state.categoryQuery == query) {
      return;
    }
    state = state.copyWith(categoryQuery: query.trim());
    if (_searchCategoriesTimer?.isActive ?? false) {
      _searchCategoriesTimer?.cancel();
    }
    _searchCategoriesTimer = Timer(
      const Duration(milliseconds: 500),
          () {
        state = state.copyWith(categories: [], dropDownCategories: []);
        fetchCategories(
          context: context,
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

  void setSelectedCategory(BuildContext context, int index) {
    if (index == -1) {
      state = state.copyWith(selectedCategory: null, hasMore: true);
    } else {
      final category = state.categories[index];
      if (category.id != state.selectedCategory?.id) {
        state = state.copyWith(selectedCategory: category, hasMore: true);
      } else {
        state = state.copyWith(selectedCategory: null, hasMore: true);
      }
    }

    _page = 0;
    fetchProducts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
    setCategoriesQuery(context, '');
  }

  void removeSelectedCategory(BuildContext context) {
    state = state.copyWith(selectedCategory: null, hasMore: true);
    _page = 0;
    fetchProducts(
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }

  Future<List<ProductData>> _loadLocalProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('local_products');
    if (productsJson != null) {
      final List<dynamic> decodedList = json.decode(productsJson);
      return decodedList.map((item) => ProductData.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _saveLocalProducts(List<ProductData> products) async {
    final prefs = await SharedPreferences.getInstance();
    final String productsJson = json.encode(products.map((product) => product.toJson()).toList());
    await prefs.setString('local_products', productsJson);
  }

  void clearCategoriesSearch(BuildContext context) {
    if (_searchCategoriesTimer?.isActive ?? false) {
      _searchCategoriesTimer?.cancel();
    }
    state = state.copyWith(
      categoryQuery: '',
      categories: [],
      dropDownCategories: [],
    );
    fetchCategories(
      context: context,
      checkYourNetwork: () {
        AppHelpers.showSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      },
    );
  }
}
