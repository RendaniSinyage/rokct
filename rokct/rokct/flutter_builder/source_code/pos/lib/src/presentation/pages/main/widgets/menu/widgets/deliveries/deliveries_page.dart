import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/deliveries/add_deliveryman_page.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/deliveries/riverpod/deliveryman_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/deliveries/widgets/deliveryman_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../../core/utils/app_helpers.dart';
import '../../../../../../theme/theme.dart';
import 'widgets/status_dialog.dart';

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({super.key});

  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(deliverymanProvider.notifier).fetchDeliverymen(
            isRefresh: true,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliverymanProvider);
    final notifier = ref.read(deliverymanProvider.notifier);
    return Scaffold(
      backgroundColor: AppStyle.bg,
      body: Column(
        children: [
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.deliveries),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: AppStyle.black),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(FlutterRemix.close_fill))
            ],
          ),
          Expanded(
            child: Padding(
              padding: REdgeInsets.symmetric(horizontal: 16),
              child: state.isLoading
                  ? const Loading()
                  : SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                          CupertinoSearchTextField(
                            prefixIcon: const Icon(FlutterRemix.search_2_line),
                            onChanged: (value) =>
                                notifier.setQuery(query: value),
                          ),
                          ListView.builder(
                          padding: REdgeInsets.symmetric(vertical: 12),
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.users.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) => DeliverymanItem(
                            user: state.users[index],
                            onTap: (status) {
                              AppHelpers.showAlertDialog(
                                context: context,
                                child:  StatusDialog(
                                  id:  state.users[index].invite?.shopId,
                                  status: status,
                                ),
                              );
                            },
                          ),
                        ),
                        HasMoreButton(hasMore: state.hasMore, onViewMore: notifier.fetchDeliverymen)

                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppHelpers.showAlertDialog(
              context: context,
              backgroundColor: AppStyle.bg,
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height/1.5,
                width: MediaQuery.sizeOf(context).width/2,
                child: const AddDeliverymanPage(),
              ));
          //notifier.addTextField();
        },
        backgroundColor: AppStyle.primary,
        child: const Icon(FlutterRemix.add_fill),
      ),
    );
  }
}

