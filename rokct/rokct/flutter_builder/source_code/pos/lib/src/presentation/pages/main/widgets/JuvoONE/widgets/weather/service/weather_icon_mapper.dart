import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class WeatherIconMapper {
  static IconData getRemixIcon(int code, {bool isNight = false}) {
    // Day/Night specific icons
    if (isNight) {
      switch (code) {
        case 1000: // Clear
          return Remix.moon_clear_fill;
        case 1003: // Partly cloudy
          return Remix.moon_cloudy_fill;
        default:
        // Continue to general mapping
          break;
      }
    }

    // General condition mapping
    switch (code) {
    // Clear conditions
      case 1000:
        return Remix.sun_fill;

    // Cloudy conditions
      case 1003: // Partly cloudy
        return Remix.sun_cloudy_fill;
      case 1006: // Cloudy
        return Remix.cloudy_fill;
      case 1009: // Overcast
        return Remix.cloud_fill;

    // Rain conditions
      case 1063: // Patchy rain possible
      case 1150: // Patchy light drizzle
      case 1153: // Light drizzle
        return Remix.drizzle_fill;
      case 1180: // Patchy light rain
      case 1183: // Light rain
      case 1186: // Moderate rain at times
      case 1189: // Moderate rain
        return Remix.showers_fill;
      case 1192: // Heavy rain at times
      case 1195: // Heavy rain
      case 1243: // Moderate or heavy rain shower
      case 1246: // Torrential rain shower
        return Remix.heavy_showers_fill;

    // Thunder conditions
      case 1087: // Thundery outbreaks possible
      case 1273: // Patchy light rain with thunder
      case 1276: // Moderate or heavy rain with thunder
        return Remix.thunderstorms_fill;

    // Snow conditions
      case 1066: // Patchy snow possible
      case 1114: // Blowing snow
      case 1210: // Patchy light snow
      case 1213: // Light snow
      case 1216: // Patchy moderate snow
      case 1219: // Moderate snow
      case 1222: // Patchy heavy snow
      case 1225: // Heavy snow
        return Remix.snowy_fill;

    // Sleet and mixed conditions
      case 1069: // Patchy sleet possible
      case 1072: // Patchy freezing drizzle possible
      case 1168: // Freezing drizzle
      case 1171: // Heavy freezing drizzle
      case 1198: // Light freezing rain
      case 1201: // Moderate or heavy freezing rain
      case 1204: // Light sleet
      case 1207: // Moderate or heavy sleet
        return Remix.hail_fill;

    // Mist and fog conditions
      case 1030: // Mist
      case 1135: // Fog
      case 1147: // Freezing fog
        return Remix.mist_fill;

    // Extreme conditions
      case 1237: // Ice pellets
        return Remix.hail_fill;
      case 1279: // Patchy light snow with thunder
      case 1282: // Moderate or heavy snow with thunder
        return Remix.snowflake_fill;

    // Default fallback
      default:
        debugPrint('Unknown weather code: $code, using default icon');
        return Remix.sun_cloudy_fill;
    }
  }

  // Helper method to determine if a condition is severe
  static bool isSevereCondition(int code) {
    return [
      1087,  // Thundery outbreaks
      1192,  // Heavy rain at times
      1195,  // Heavy rain
      1246,  // Torrential rain shower
      1276,  // Heavy rain with thunder
      1282,  // Heavy snow with thunder
    ].contains(code);
  }

  // Helper method to determine if a condition indicates precipitation
  static bool isPrecipitation(int code) {
    return (code >= 1150 && code <= 1201) ||  // Rain and drizzle
        (code >= 1210 && code <= 1225) ||  // Snow
        (code >= 1240 && code <= 1246);    // Showers
  }

  // Helper method to get text description for a condition code
  static String getConditionDescription(int code) {
    switch (code) {
      case 1000:
        return 'Clear';
      case 1003:
        return 'Partly cloudy';
      case 1006:
        return 'Cloudy';
      case 1009:
        return 'Overcast';
      case 1030:
        return 'Mist';
      case 1063:
        return 'Patchy rain possible';
      case 1066:
        return 'Patchy snow possible';
      case 1069:
        return 'Patchy sleet possible';
      case 1072:
        return 'Patchy freezing drizzle possible';
      case 1087:
        return 'Thundery outbreaks possible';
      case 1114:
        return 'Blowing snow';
      case 1117:
        return 'Blizzard';
      case 1135:
        return 'Fog';
      case 1147:
        return 'Freezing fog';
      case 1150:
        return 'Patchy light drizzle';
      case 1153:
        return 'Light drizzle';
      case 1168:
        return 'Freezing drizzle';
      case 1171:
        return 'Heavy freezing drizzle';
      case 1180:
        return 'Patchy light rain';
      case 1183:
        return 'Light rain';
      case 1186:
        return 'Moderate rain at times';
      case 1189:
        return 'Moderate rain';
      case 1192:
        return 'Heavy rain at times';
      case 1195:
        return 'Heavy rain';
      case 1198:
        return 'Light freezing rain';
      case 1201:
        return 'Moderate or heavy freezing rain';
      case 1204:
        return 'Light sleet';
      case 1207:
        return 'Moderate or heavy sleet';
      case 1210:
        return 'Patchy light snow';
      case 1213:
        return 'Light snow';
      case 1216:
        return 'Patchy moderate snow';
      case 1219:
        return 'Moderate snow';
      case 1222:
        return 'Patchy heavy snow';
      case 1225:
        return 'Heavy snow';
      case 1237:
        return 'Ice pellets';
      case 1240:
        return 'Light rain shower';
      case 1243:
        return 'Moderate or heavy rain shower';
      case 1246:
        return 'Torrential rain shower';
      case 1249:
        return 'Light sleet showers';
      case 1252:
        return 'Moderate or heavy sleet showers';
      case 1255:
        return 'Light snow showers';
      case 1258:
        return 'Moderate or heavy snow showers';
      case 1261:
        return 'Light showers of ice pellets';
      case 1264:
        return 'Moderate or heavy showers of ice pellets';
      case 1273:
        return 'Patchy light rain with thunder';
      case 1276:
        return 'Moderate or heavy rain with thunder';
      case 1279:
        return 'Patchy light snow with thunder';
      case 1282:
        return 'Moderate or heavy snow with thunder';
      default:
        return 'Unknown';
    }
  }
}
