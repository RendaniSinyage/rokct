import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../theme/theme.dart';
import 'extended_forecast_view.dart';
import 'service/open_weather_service.dart';

class ExtendedForecastLoader extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;

  const ExtendedForecastLoader({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  ConsumerState<ExtendedForecastLoader> createState() => _ExtendedForecastLoaderState();
}

class _ExtendedForecastLoaderState extends ConsumerState<ExtendedForecastLoader> {
  bool _isExpanded = false;
  bool _isLoading = false;

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(openWeatherProvider.notifier).loadExtendedForecast(
        widget.latitude,
        widget.longitude,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load extended forecast',
              style: GoogleFonts.inter(color: AppStyle.white),
            ),
            backgroundColor: AppStyle.black,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openWeatherState = ref.watch(openWeatherProvider);

    return Column(
      children: [
        // View More tile
        ListTile(
          title: Text(
            'View More Days',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
          trailing: _isLoading
              ? SizedBox(
            width: 24.sp,
            height: 24.sp,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppStyle.black),
            ),
          )
              : Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppStyle.black,
          ),
          onTap: () async {
            if (_isLoading) return;

            setState(() {
              _isExpanded = !_isExpanded;
            });

            if (_isExpanded && !openWeatherState.hasValue) {
              await _loadData();
            }
          },
        ),

        // Show extended forecast when expanded
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          const ExtendedForecastView(),
        ],
      ],
    );
  }
}
