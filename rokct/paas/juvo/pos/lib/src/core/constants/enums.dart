// Create an enum for terminal payment status
enum TerminalPaymentStatus { initiating, connecting, pairing,
  processing,  completed,  failed }

enum SnackBarType { success, info, error }

enum DropDownType { deliveryman, users,section, table }

enum ExtrasType { color, text, image }

enum ChairPosition { top, bottom, left, right }

enum ProductStatus { published, pending, unpublished }

enum UploadType { extras, brands, categories, shopsLogo,
  shopsBack,  products, reviews, users,  discounts }

enum DeliveryType { delivery, pickup }

enum OrderStatus { newOrder, accepted, cooking, ready,
  onAWay, delivered, canceled }

enum WeekDays { monday,  tuesday,  wednesday,  thursday,
  friday,  saturday,  sunday }

///Maintenance
enum FilterLocation { pre, ro, post }
enum FilterType { birm, sediment, carbonBlock }

///Tanks
enum TankType {raw, purified}
enum TankStatus {full, empty, halfEmpty, quarterEmpty}

enum MaintenanceStage {
  initialCheck,
  pressureRelease,
  backwash,
  settling,
  fastWash,
  stabilization,
  returnToFilter,
  brineAndSlowRinse,
  fastRinse,
  brineRefill,
  returnToService;

  // Add properties and methods to the enum
  String get name {
    switch (this) {
      case MaintenanceStage.initialCheck:
        return 'Initial Check';
      case MaintenanceStage.pressureRelease:
        return 'Pressure Release';
      case MaintenanceStage.backwash:
        return 'Backwash';
      case MaintenanceStage.settling:
        return 'Settling';
      case MaintenanceStage.fastWash:
        return 'Fast Wash';
      case MaintenanceStage.stabilization:
        return 'Stabilization';
      case MaintenanceStage.returnToFilter:
        return 'Return to Filter';
      case MaintenanceStage.brineAndSlowRinse:
        return 'Brine and Slow Rinse';
      case MaintenanceStage.fastRinse:
        return 'Fast Rinse';
      case MaintenanceStage.brineRefill:
        return 'Brine Refill';
      case MaintenanceStage.returnToService:
        return 'Return to Service';
    }
  }

  Duration get duration {
    switch (this) {
      case MaintenanceStage.initialCheck:
        return const Duration(minutes: 5);
      case MaintenanceStage.pressureRelease:
        return const Duration(minutes: 10);
      case MaintenanceStage.backwash:
        return const Duration(minutes: 15);
      case MaintenanceStage.settling:
        return const Duration(minutes: 10);
      case MaintenanceStage.fastWash:
        return const Duration(minutes: 10);
      case MaintenanceStage.stabilization:
        return const Duration(minutes: 15);
      case MaintenanceStage.returnToFilter:
        return const Duration(minutes: 5);
      case MaintenanceStage.brineAndSlowRinse:
        return const Duration(minutes: 20);
      case MaintenanceStage.fastRinse:
        return const Duration(minutes: 10);
      case MaintenanceStage.brineRefill:
        return const Duration(minutes: 15);
      case MaintenanceStage.returnToService:
        return const Duration(minutes: 5);
    }
  }

  // Helper to get stages for vessel type
  static List<MaintenanceStage> getStagesForVesselType(String type) {
    if (type == 'megaChar') {
      return [
        MaintenanceStage.initialCheck,
        MaintenanceStage.pressureRelease,
        MaintenanceStage.backwash,
        MaintenanceStage.settling,
        MaintenanceStage.fastWash,
        MaintenanceStage.stabilization,
        MaintenanceStage.returnToFilter,
      ];
    } else { // softener
      return [
        MaintenanceStage.initialCheck,
        MaintenanceStage.pressureRelease,
        MaintenanceStage.backwash,
        MaintenanceStage.settling,
        MaintenanceStage.brineAndSlowRinse,
        MaintenanceStage.fastRinse,
        MaintenanceStage.brineRefill,
        MaintenanceStage.stabilization,
        MaintenanceStage.returnToService,
      ];
    }
  }

  // Helper to get next stage
  static MaintenanceStage? getNextStage(String type, MaintenanceStage currentStage) {
    final stages = getStagesForVesselType(type);
    final currentIndex = stages.indexOf(currentStage);
    if (currentIndex == -1 || currentIndex == stages.length - 1) {
      return null;
    }
    return stages[currentIndex + 1];
  }

}
