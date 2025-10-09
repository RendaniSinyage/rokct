import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/language/select_item.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../../../components/loading.dart';
import 'riverpod/provider/languages_provider.dart';

class LanguagesModal extends ConsumerWidget {
  final VoidCallback? afterUpdate;

  const LanguagesModal({super.key, this.afterUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languagesProvider.notifier);
    final state = ref.watch(languagesProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 15,vertical: 10),
          child: Row(
            children: [
              Text(
                AppHelpers.getTranslation(
                    TrKeys.language),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: AppStyle.black,
                ),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  splashRadius: 25,
                  icon: const Icon(
                      FlutterRemix.close_fill,
                  color: AppStyle.black,))
            ],
          ),
        ),
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 16),
          child: state.isLoading
              ? const Loading()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: REdgeInsets.only(top: 6, bottom: 6),
                  itemCount: state.languages.length,
                  itemBuilder: (context, index) {
                    return SelectItem(
                      isLast: state.languages.length-1==index,
                      onTap: () {
                        notifier.change(index, afterUpdate: afterUpdate);
                        Navigator.pop(context);
                      },
                      isActive: LocalStorage.getLanguage()?.locale ==
                          state.languages[index].locale,
                      title: state.languages[index].title ?? '',
                    );
                  },
                ),
        ),
        12.verticalSpace,
      ],
    );
  }
}

