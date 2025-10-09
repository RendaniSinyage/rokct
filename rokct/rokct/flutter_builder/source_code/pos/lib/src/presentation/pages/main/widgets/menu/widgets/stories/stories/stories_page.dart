import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import '../edit_stories/riverpod/provider/edit_stories_provider.dart';
import '../riverpod/provider/stories_provider.dart';
import 'create/create_stories_page.dart';
import 'edit/edit_stories_page.dart';
import 'widgets/stories_item.dart';


class StoriesPage extends ConsumerStatefulWidget {
  const StoriesPage({super.key});

  @override
  ConsumerState<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends ConsumerState<StoriesPage> {
  late RefreshController controller;

  @override
  void initState() {
    controller = RefreshController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(storiesProvider.notifier)
          .fetchStories(context: context, isRefresh: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storiesProvider);
    final notifier = ref.read(storiesProvider.notifier);
    return Scaffold(
      backgroundColor: AppStyle.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.stories),
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
            child: state.isLoading
                ? const Center(child: Loading())
                : SmartRefresher(
                    controller: controller,
                    enablePullDown: true,
                    enablePullUp: true,
                    onRefresh: () => notifier.fetchStories(
                        controller: controller, isRefresh: true),
                    onLoading: () =>
                        notifier.fetchStories(controller: controller),
                    child: state.stories.isEmpty
                        ? const NoItem(title: TrKeys.noStories)
                        : AnimationLimiter(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: REdgeInsets.only(
                                  top: 16, bottom: 56.r, left: 12, right: 12),
                              shrinkWrap: true,
                              itemCount: state.stories.length,
                              itemBuilder: (context, index) =>
                                  AnimationConfiguration.staggeredList(
                                position: index,
                                duration: AppConstants.animationDuration,
                                child: ScaleAnimation(
                                  scale: 0.5,
                                  child: FadeInAnimation(
                                    child: StoriesItem(
                                      stories: state.stories[index],
                                      spacing: 10,
                                      onEdit: () {
                                        controller.resetNoData();
                                        ref
                                            .read(
                                                editStoriesProvider.notifier)
                                            .setStoryDetails(
                                                state.stories[index]);
                                        AppHelpers.showAlertDialog(
                                            context: context,
                                            child: EditStoriesPage((){}));

                                      },

                                      onDelete: () {
                                        showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              titlePadding: const EdgeInsets.all(16),
                                              actionsPadding: const EdgeInsets.all(16),
                                              title: Text(
                                                AppHelpers.getTranslation(TrKeys.deleteProduct),
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  color: AppStyle.black,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              actions: [
                                                SizedBox(
                                                  width: 112.r,
                                                  child: ConfirmButton(
                                                      paddingSize: 0,
                                                      title: AppHelpers.getTranslation(TrKeys.no),
                                                      onTap: () => Navigator.pop(context)),
                                                ),
                                                SizedBox(
                                                  width: 112.r,
                                                  child: ConfirmButton(
                                                      paddingSize: 0,
                                                      title: AppHelpers.getTranslation(TrKeys.yes),
                                                      onTap: () {
                                                        notifier.deleteStories(
                                                            context: context,
                                                            id: state
                                                                .stories[index].id);

                                                        Navigator.pop(context);
                                                      }),
                                                ),
                                              ],
                                            )
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
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
                child: const CreateStoriesPage(),
              ));
          //notifier.addTextField();
        },
        backgroundColor: AppStyle.primary,
        child: const Icon(FlutterRemix.add_fill),
      ),
    );
  }
}

