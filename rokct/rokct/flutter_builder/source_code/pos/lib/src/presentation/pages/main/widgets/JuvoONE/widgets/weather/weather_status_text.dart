import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../theme/theme.dart';
import 'service/weather_state.dart';

class WeatherStatusText extends StatelessWidget {
  final WeatherState weatherState;

  const WeatherStatusText({
    super.key,
    required this.weatherState,
  });

  String _cleanText(String text) {
    return text.replaceAll(' nearby', '');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 3), (i) => i),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();

        final cyclePosition = snapshot.data! % (weatherState.alerts.isEmpty ? 2 : 3);
        String displayText;
        Color textColor;

        if (weatherState.alerts.isNotEmpty && cyclePosition == 2) {
          displayText = _cleanText(weatherState.alerts.first['event'] ?? 'Weather Alert');
          textColor = AppStyle.red;
        } else if (cyclePosition == 1) {
          displayText = _cleanText(weatherState.condition['text']);
          textColor = AppStyle.black;
        } else {
          displayText = 'Tomorrow';
          textColor = AppStyle.black;
        }

        return Padding(
          padding: EdgeInsets.only(top: 0.5.sp),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 10.sp,
              color: textColor,
              height: 1,
            ),
          ),
        );
      },
    );
  }
}
