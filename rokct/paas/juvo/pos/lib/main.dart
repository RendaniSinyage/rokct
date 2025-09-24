import 'package:admin_desktop/src/presentation/components/loading_animation.dart';
import 'package:admin_desktop/src/repository/repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

import 'src/app_widget.dart';
import 'src/core/constants/constants.dart';
import 'src/core/di/dependency_manager.dart';
import 'src/core/utils/utils.dart';
import 'dart:io' show Platform;

import 'src/core/utils/second_screen_service.dart';
import 'src/presentation/pages/main/widgets/JuvoONE/widgets/toggles.dart';
import 'src/presentation/pages/main/widgets/notifications/riverpod/notification_provider.dart';
import 'src/presentation/pages/main/widgets/notifications/riverpod/notification_state.dart';

// Global variables
bool isFullScreen = false;
bool isAlwaysOnTop = true;
late Size windowSize;
late Display primaryDisplay;

// Function to update notification count in SharedPreferences
Future<void> updateNotificationCount(int count) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', count);
    if (kDebugMode) {
      print('Notification count updated: $count');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error updating notification count: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<int> getOtherTranslation(int arg) async {
  final settingsRepository = SettingsSettingsRepositoryImpl();
  final res = await settingsRepository.getLanguages();
  res.when(
    success: (l) {
      l.data?.forEach((e) async {
        final translations =
        await settingsRepository.getMobileTranslations(lang: e.locale);
        translations.when(
          success: (d) {
            LocalStorage.setOtherTranslations(
                translations: d.data, key: e.id.toString());
          },
          failure: (f) => null,
        );
      });
    },
    failure: (f) => null,
  );
  return 0;
}

void main() async {
  try {
    if (kDebugMode) {
      print('Starting initialization');
    }
    WidgetsFlutterBinding.ensureInitialized();
    await preloadFont();

    if (kDebugMode) {
      print('Flutter binding initialized');
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final wasMaximized = prefs.getBool('wasMaximized') ?? false;

    if (kDebugMode) {
      print('SharedPreferences initialized');
    }

    // Load the WaterOS state
    final waterOSEnabled = prefs.getBool('enableJuvoONE') ?? false;
    AppConstants.enableJuvoONE = waterOSEnabled;
    if (kDebugMode) {
      print('WaterOS state loaded: $waterOSEnabled');
    }

    // Load the SecondScreen state
    final secondScreenEnabled = prefs.getBool('secondScreen') ?? false;
    AppConstants.secondScreen = secondScreenEnabled;
    if (kDebugMode) {
      print('SecondScreen state loaded: $secondScreenEnabled');
    }

    // Load the skipPin state
    final skipPinEnabled = prefs.getBool('skipPin') ?? false;
    AppConstants.skipPin = skipPinEnabled;
    if (kDebugMode) {
      print('skipPin state loaded: $skipPinEnabled');
    }

    // Load the autoDeliver state
    final autoDeliverEnabled = prefs.getBool('autoDeliver') ?? false;
    AppConstants.autoDeliver = autoDeliverEnabled;
    if (kDebugMode) {
      print('autoDeliver state loaded: $autoDeliverEnabled');
    }

    setUpDependencies();
    if (kDebugMode) {
      print('Dependencies set up');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      if (kDebugMode) {
        print('Firebase initialized for mobile');
      }
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      if (kDebugMode) {
        print('Initializing for desktop');
      }
      await windowManager.ensureInitialized();
      if (kDebugMode) {
        print('windowManager initialized');
      }

      // Get the primary display
      primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();

      WindowOptions windowOptions = WindowOptions(
        size: Size(primaryDisplay.size.width, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setAlwaysOnTop(true);
        if (wasMaximized) {
          await windowManager.maximize();
        }
      });

      // Set up window event listeners
      windowManager.addListener(MyWindowListener());

      if (kDebugMode) {
        print('Window setup complete and always on top');
      }

      // Set up keyboard listener for F11 key
      RawKeyboard.instance.addListener(_handleKeyPress);

      // Update windowSize with the new dimensions
      windowSize = Size(primaryDisplay.size.width, 720);

      // Set up a listener for notification changes
      final container = ProviderContainer();
      container.listen<NotificationState>(
        notificationProvider,
            (previous, next) {
          final count = next.countOfNotifications?.notification ?? 0;
          updateNotificationCount(count);
          if (kDebugMode) {
            print('Notification state changed. New count: $count');
          }
        },
      );

      // Test SharedPreferences
      await prefs.setInt('testKey', 42);
      final testValue = prefs.getInt('testKey');
      if (kDebugMode) {
        print('Test SharedPreferences value: $testValue');
      }
    }

    await LocalStorage.init();
    if (kDebugMode) {
      print('LocalStorage initialized');
    }

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (kDebugMode) {
      print('Screen orientation set');
    }

    // Initialize SecondScreenService
    final container = ProviderContainer();
    await container.read(secondScreenServiceProvider).startServer();
    if (kDebugMode) {
      print('SecondScreenService initialized');
    }

    if (LocalStorage.getTranslations().isNotEmpty) {
      fetchSettingNoAwait();
    }
    isolate();

    if (kDebugMode) {
      print('Running app');
    }
    runApp(
      ProviderScope(
        overrides: [
          waterOSToggleProvider.overrideWith(
                (ref) => WaterOSToggleNotifier()..toggle(waterOSEnabled),
          ),
          secondScreenToggleProvider.overrideWith(
                (ref) => SecondScreenToggleNotifier()..toggle(secondScreenEnabled),
          ),
          skipPINToggleProvider.overrideWith(
                (ref) => SkipPINToggleNotifier()..toggle(skipPinEnabled),
          ),
          autoDeliverProvider.overrideWith(
                (ref) => autoDeliverNotifier()..toggle(autoDeliverEnabled),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(1194, 834),
          builder: (context, child) => const AppWidget(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Initialization error: $e');
      print('Stack trace: $stackTrace');
    }
    // Consider showing an error dialog or screen here
  }
}

void _handleKeyPress(RawKeyEvent event) {
  if (event is RawKeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullScreen();
    }
  }
}

void _toggleFullScreen() async {
  isFullScreen = !isFullScreen;
  await windowManager.setFullScreen(isFullScreen);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> fetchSettingNoAwait() async {
  final settingsRepository = SettingsSettingsRepositoryImpl();
  settingsRepository.getGlobalSettings();
  settingsRepository.getLanguages();
  settingsRepository.getTranslations();
}

Future<Future<FlutterIsolate>> isolate() async {
  return FlutterIsolate.spawn(getOtherTranslation, 0);
}

Future<void> saveWindowState() async {
  final prefs = await SharedPreferences.getInstance();
  final isMaximized = await windowManager.isMaximized();
  await prefs.setBool('wasMaximized', isMaximized);
}

class MyWindowListener extends WindowListener {
  @override
  void onWindowEvent(String eventName) {
    if (kDebugMode) {
      print('[WindowManager] onWindowEvent: $eventName');
    }
  }

  @override
  void onWindowMaximize() async {
    await saveWindowState();
  }

  @override
  void onWindowUnmaximize() async {
    await saveWindowState();
  }

  @override
  void onWindowRestore() async {
    await saveWindowState();
  }
}
