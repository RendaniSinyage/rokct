import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

import '../../theme/theme.dart';


class MakeShimmer extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const MakeShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
  }) ;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Shimmer.fromColors(
            baseColor: AppStyle.bottomNavigationBarColor,
            highlightColor: AppStyle.shimmerHighlight,
            child: child,
          )
        : child;
  }
}

