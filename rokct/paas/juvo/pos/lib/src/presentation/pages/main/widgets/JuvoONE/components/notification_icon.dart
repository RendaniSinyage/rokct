import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../theme/theme.dart';
import '../../notifications/notification_dialog.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/notifications/riverpod/notification_provider.dart';

class NotificationIcon extends ConsumerStatefulWidget {
  const NotificationIcon({super.key});

  @override
  ConsumerState<NotificationIcon> createState() => _NotificationIconState();  }

class _NotificationIconState extends ConsumerState<NotificationIcon> with SingleTickerProviderStateMixin {  // Change to ConsumerState
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (ref.watch(notificationProvider).countOfNotifications?.notification != null &&
            ref.watch(notificationProvider).countOfNotifications!.notification! > 0)
          Positioned(
            top: 7,
            right: 6,
            child: FadeTransition(
              opacity: _animation,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppStyle.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: AlertDialog(
                      content: NotificationDialog(),
                      backgroundColor: AppStyle.transparent,
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(
            Remix.notification_2_line,
            color: AppStyle.black,
          ),
        ),
      ],
    );
  }
}
