import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../components/components.dart';
import '../../../../theme/theme.dart';
import 'page_view_item.dart';
import 'riverpod/right_side_provider.dart';

class RightSide extends ConsumerStatefulWidget {
  const RightSide({super.key});

  @override
  ConsumerState<RightSide> createState() => _RightSideState();
}

class _RightSideState extends ConsumerState<RightSide> {
  late PageController _pageController;
  List<AudioPlayer> _audioPlayers = [];
  int _currentPlayerIndex = 0;
  static const int _maxAudioPlayers = 5;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    for (int i = 0; i < _maxAudioPlayers; i++) {
      _audioPlayers.add(AudioPlayer());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rightSideProvider.notifier)
        ..fetchBags()
        ..fetchCurrencies(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
            _playSound('wrong.wav');
          },
        )
        ..fetchPayments(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
            _playSound('wrong.wav');
          },
        )
        ..fetchCarts(
          checkYourNetwork: () {
            AppHelpers.showSnackBar(
              context,
              AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
            );
            _playSound('wrong.wav');
          },
        );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var player in _audioPlayers) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _playSound(String soundFile) async {
    if (AppConstants.sound) {
      final player = _audioPlayers[_currentPlayerIndex];
      await player.play(AssetSource('sounds/$soundFile'));
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _maxAudioPlayers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rightSideProvider);
    final notifier = ref.read(rightSideProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56.r,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: state.bags.length,
                  itemBuilder: (context, index) {
                    final bag = state.bags[index];
                    final bool isSelected = state.selectedBagIndex == index;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: () {
                            notifier.setSelectedBagIndex(index);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                            _playSound('tap.wav');
                          },
                          child: Container(
                            height: 56.r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              color: isSelected
                                  ? AppStyle.brandGreen
                                  : AppStyle.brandGreen.withOpacity(0.1),
                            ),
                            padding: REdgeInsets.only(
                              left: 20,
                              right: index == 0 ? 20 : 4,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  FlutterRemix.shopping_bag_3_fill,
                                  size: 20.r,
                                  color: isSelected
                                      ? AppStyle.black
                                      : AppStyle.brandGreen.withOpacity(0.5),
                                ),
                                8.horizontalSpace,
                                Text(
                                  '${AppHelpers.getTranslation(TrKeys.bag)} - ${(bag.index ?? 0) + 1}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: isSelected
                                        ? AppStyle.black
                                        : AppStyle.brandGreen.withOpacity(0.5),
                                    letterSpacing: -14 * 0.02,
                                  ),
                                ),
                                if (index != 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      16.horizontalSpace,
                                      CircleIconButton(
                                        backgroundColor: AppStyle.transparent,
                                        iconData: FlutterRemix.close_line,
                                        icon: isSelected
                                            ? AppStyle.black
                                            : AppStyle.primary,
                                        onTap: () {
                                          notifier.removeBag(index);
                                          _playSound('wrong.wav');
                                        },
                                        size: 30,
                                      )
                                    ],
                                  )
                              ],
                            ),
                          ),
                        ),
                        4.horizontalSpace,
                      ],
                    );
                  },
                ),
              ),
            ),
            9.horizontalSpace,
            InkWell(
              onTap: () {
                notifier.addANewBag();
                _playSound('tap.wav');
              },
              child: AnimationButtonEffect(
                child: Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      color: AppStyle.brandGreen),
                  child: const Center(child: Icon(FlutterRemix.add_line,
                      color: AppStyle.black)),
                ),
              ),
            ),
          ],
        ),
        6.verticalSpace,
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: state.bags.map((bag) => PageViewItem(
              bag: bag,
              onAddItem: () => _playSound('tap.wav'),
              onRemoveItem: () => _playSound('wrong.wav'),
            )).toList(),
          ),
        )
      ],
    );
  }
}
