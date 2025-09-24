import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/theme.dart';
import 'service/weather_icon_mapper.dart';

class WeatherIcon extends StatelessWidget {
  final Map<String, dynamic> condition;
  final double size;
  final Color? color;
  final bool isNight;

  const WeatherIcon({
    Key? key,
    required this.condition,
    required this.size,
    this.color,
    this.isNight = false,
  }) : super(key: key);

  IconData _getLocalIcon() {
    try {
      final conditionCode = condition['code'] as int?;
      if (conditionCode == null) return Remix.cloud_fill;

      return WeatherIconMapper.getRemixIcon(
        conditionCode,
        isNight: isNight,
      );
    } catch (e) {
      debugPrint('Error getting local weather icon: $e');
      return Remix.cloud_fill;
    }
  }

  Widget _buildNetworkIcon(String iconUrl) {
    return CachedNetworkImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) {
        debugPrint('Error loading weather icon: $error');
        return _buildLocalIcon();
      },
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          _buildLoadingIndicator(downloadProgress.progress),
    );
  }

  Widget _buildLocalIcon() {
    return Icon(
      _getLocalIcon(),
      size: size,
      color: color ?? AppStyle.black,
    );
  }

  Widget _buildLoadingIndicator(double? progress) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          color: color ?? AppStyle.black,
        ),
      ),
    );
  }

  String? _getIconUrl() {
    try {
      final iconPath = condition['icon'] as String?;
      if (iconPath == null || iconPath.isEmpty) return null;

      // Ensure URL starts with https://
      if (!iconPath.startsWith('http')) {
        return 'https:$iconPath';
      }
      return iconPath;
    } catch (e) {
      debugPrint('Error getting weather icon URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Early return if condition is null or empty
    if (condition.isEmpty) {
      return _buildLocalIcon();
    }

    // Use local icons if network icons are disabled
    if (!AppConstants.weatherIcon) {
      return _buildLocalIcon();
    }

    // Get icon URL
    final iconUrl = _getIconUrl();
    if (iconUrl == null) {
      return _buildLocalIcon();
    }

    return _buildNetworkIcon(iconUrl);
  }
}
