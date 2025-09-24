import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

abstract class AppConnectivity {
  AppConnectivity._();

  static Future<bool> connectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    }
    return false;
  }

  // New method that automatically shows dialog when no connection
  static Future<bool> connectivityWithDialog(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (!hasConnection) {
      // Automatically show dialog when no connection
      AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }

  // Alternative: Replace the existing method to always show dialog
  static Future<bool> connectivityAndShowDialog(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (!hasConnection) {
      AppHelpers.showNoConnectionDialog(context);
    }

    return hasConnection;
  }
}
