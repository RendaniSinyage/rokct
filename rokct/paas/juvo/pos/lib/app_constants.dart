abstract class AppConstants {
  AppConstants._();

  static const String baseUrl = "https://api.juvo.app/";
  static const String webUrl = "https://web.juvo.app/";

  static const bool autoTrn = true;
  static const bool isDemo = false;

  static bool playMusicOnOrderStatusChange = true;
  static bool keepPlayingOnNewOrder = true;

  static const String demoSellerLogin = 'sellers@githubit.com';
  static const String demoSellerPassword = 'seller';
  static const String demoCookerLogin = 'cook@githubit.com';
  static const String demoCookerPassword = 'cook';
  static const String demoWaiterLogin = 'waiter@githubit.com';
  static const String demoWaiterPassword = 'githubit';


  static const Duration refreshTime = Duration(seconds: 10);
  static const double demoLatitude = -22.34058;
  static const double demoLongitude = 30.01341;
  static const double pinLoadingMin = 0.116666667;
  static const double pinLoadingMax = 0.611111111;
  static const Duration animationDuration = Duration(milliseconds: 375);
  static const Duration weatherRefresher = Duration(minutes: 360);


  static const double radius = 12;

/// JuvoONE
  static const String keyShopData = 'keyShopData';
  static bool autoDeliver = false;
  static bool secondScreen = false;
  static bool enableJuvoONE = true;
  static bool skipPin = false;
  static bool useDummyDataFallback = true;
  static bool enableOfflineMode = true;
  static bool sound = true;
  //After this period the app on Desktop goes to Idle, it shows the Dashboard
  static Duration idleTimeout = const Duration(minutes: 15);
  static Duration fetchTime = const Duration(seconds: 60);
  static Duration dashboardFetchTime = const Duration(minutes: 45);
  static String googleApiKey = 'AIzaSyDJjLCq6HBCe7xae6l0D9DW1MWpE4900GU';
  static String openWeatherApiKey = '9fcb56b26484500d5db76b8ab71cdcdf';
  static bool weatherIcon = true;
  static var rainPOP = 60;
  static String chatGpt = '';

  /// Optimized stock ids
  static final OptimizedStockIds stockIds = OptimizedStockIds();

  // Yoco related constants
  static const String YOCO_PUBLIC_KEY = 'yoco_public_key';
  static const String YOCO_PRIVATE_KEY = 'yoco_private_key';
  static const String YOCO_PAIRED_DEVICE = 'yoco_paired_device';
  static const String YOCO_ENVIRONMENT = 'yoco_environment';

  static const String terminal = 'terminal';
  static const String terminalPayment = 'terminal_payment';
  static const String processingPayment = 'processing_payment';
  static const String paymentComplete = 'payment_complete';
  static const String paymentFailed = 'payment_failed';

  // Add Yoco test credentials
  static const String YOCO_TEST_PUBLIC_KEY = 'pk_test_abba4d87oW2YObW00794';
  static const String YOCO_TEST_PRIVATE_KEY = 'sk_test_7e518341k3nGzD35bcf4361b7342';

  ///OrderUsageDate
  static String dateAt = 'createdAt';

  ///QuickSale
  // Comma-separated list of stock IDs for no-user mode
  static const List<int> quickSaleNoUserStockIds = [669,670,671,672,668];
  // Default quantity for quick sale orders
  static const int quickSaleDefaultQuantity = 1;
  // Maximum number of taps for user mode (for coupon)
  static const int quickSaleCouponTapCount = 4;
  // Stock ID for regular user mode
  static const int quickSaleStockId = 672;
  // Coupon code to apply when tap count reaches maximum in user mode
  static const String quickSaleCouponCode = "FREE25";

/// Maintenance constants
  // Maintenance check intervals (in days)
  static const maintenanceCheckDays = 7;
  static const preFilterReplaceDays = 30;
  static const postFilterReplaceDays = 90;
  static const roFilterReplaceDays = 180;
  static const vesselReplaceDays = 365;
  static const roMembraneReplaceDays = 365;

  // Maintenance procedure durations (in minutes)
  static const megaCharMaintenanceDurations = {
    'initialCheck': 0,
    'pressureRelease': 2,
    'backwash': 10,
    'settling': 2,
    'fastWash': 10,
    'stabilization': 2,
    'returnToFilter': 0,
  };

  static const softenerMaintenanceDurations = {
    'initialCheck': 0,
    'pressureRelease': 2,
    'backwash': 10,
    'settling': 2,
    'brineAndSlowRinse': 30,
    'fastRinse': 10,
    'brineRefill': 5,
    'stabilization': 2,
    'returnToService': 0,
  };

  static const maintenanceTypes = {
    'megaChar': 'Megachar',
    'softener': 'Softener',
    'preFilter': 'Pre Filter',
    'roFilter': 'RO Filter',
    'postFilter': 'Post Filter',
    'roMembrane': 'RO Membrane'
  };

  static const filterTypes = {
    'birm': 'Birm',
    'sediment': 'Sediment',
    'carbonBlock': 'Carbon Block/CTO'
  };

  /// shared preferences keys
  static const String keyLangSelected = 'keyLangSelected';
  static const String keyLanguageData = 'keyLanguageData';
  static const String keyToken = 'keyToken';
  static const String keyGlobalSettings = 'keyGlobalSettings';
  static const String keyActiveLocale = 'keyActiveLocale';
  static const String keyTranslations = 'keyTranslations';
  static const String keySelectedCurrency = 'keySelectedCurrency';
  static const String keyLangLtr = 'keyLangLtr';
  static const String keyBags = 'keyBags';
  static const String keyUser = 'keyUser';
  static const String pinCode = 'pinCode';
}

class OptimizedStockIds {
  static final Map<String, int> _optimizedStockIds = {
    '672, 295, 303': 25,
    '671, 293, 301': 20,
    '670, 291, 299': 10,
    '669, 281, 297, 298': 5,
    '668': 3,
  };

  int? operator [](String prop) {
    for (final entry in _optimizedStockIds.entries) {
      if (entry.key.split(', ').contains(prop)) {
        return entry.value;
      }
    }
    return null; // or a default value
  }
}




