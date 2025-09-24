import 'package:admin_desktop/src/presentation/pages/main/riverpod/provider/main_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../../../components/components.dart';
import '../../edit_stories/riverpod/provider/edit_stories_provider.dart';

class ProductsModal extends ConsumerStatefulWidget {
  const ProductsModal({super.key});

  @override
  ConsumerState<ProductsModal> createState() => _ProductsModalState();
}

class _ProductsModalState extends ConsumerState<ProductsModal> {
  late RefreshController refreshController;

  @override
  void initState() {
    refreshController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.watch(mainProvider).products.isEmpty) {
        ref.read(mainProvider.notifier).fetchProducts(isRefresh: true);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mainProvider);
    final notifier = ref.read(mainProvider.notifier);
    return Column(
      children: [
        Expanded(
          child: state.isProductsLoading
              ? const Loading()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: state.products.length,
                        itemBuilder: (context, index) => ProductListItem(
                          product: state.products[index],
                          onTap: () {
                            ref
                                .read(editStoriesProvider.notifier)
                                .setProduct(state.products[index]);
                            Navigator.pop(context);
                          },
                          isSelected: ref
                                  .watch(editStoriesProvider)
                                  .selectProduct
                                  ?.id ==
                              state.products[index].id,
                        ),
                      ),
                      HasMoreButton(
                        hasMore: state.hasMore,
                        onViewMore: () {
                          notifier.fetchProducts();
                        },
                      ),
                      20.verticalSpace,
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

