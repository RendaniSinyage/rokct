import 'package:admin_desktop/src/models/models.dart';

class ResourceData {
  ResourceData({
    this.shopId,
    this.tanks,
    this.roSystem,
    this.maintenance,
    this.energyPurchases,
  });

  ResourceData.fromJson(Map<String, dynamic> json) {
    shopId = json['shopId'];
    if (json['tanks'] != null) {
      tanks = <TankData>[];
      json['tanks'].forEach((v) {
        tanks!.add(TankData.fromJson(v));
      });
    }
    roSystem = json['roSystem'] != null
        ? ROSystemData.fromJson(json['roSystem'])
        : null;
    maintenance = json['maintenance'] != null
        ? MaintenanceData.fromJson(json['maintenance'])
        : null;
    if (json['energyPurchases'] != null) {
      energyPurchases = <EnergyPurchaseData>[];
      json['energyPurchases'].forEach((v) {
        energyPurchases!.add(EnergyPurchaseData.fromJson(v));
      });
    }
  }

  int? shopId;
  List<TankData>? tanks;
  ROSystemData? roSystem;
  MaintenanceData? maintenance;
  List<EnergyPurchaseData>? energyPurchases;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shopId'] = shopId;
    if (tanks != null) {
      data['tanks'] = tanks!.map((v) => v.toJson()).toList();
    }
    if (roSystem != null) {
      data['roSystem'] = roSystem!.toJson();
    }
    if (maintenance != null) {
      data['maintenance'] = maintenance!.toJson();
    }
    if (energyPurchases != null) {
      data['energyPurchases'] =
          energyPurchases!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TankData {
  TankData({
    this.number,
    this.type,
    this.capacity,
    this.lastUpdated,
    this.lastFull,
    this.waterQuality,
    this.pumpStatus,
  });

  TankData.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    type = json['type'];
    capacity = json['capacity'];
    lastUpdated = DateTime.tryParse(json['lastUpdated']);
    lastFull = DateTime.tryParse(json['lastFull']);
    waterQuality = json['waterQuality'] != null
        ? WaterQualityData.fromJson(json['waterQuality'])
        : null;
    pumpStatus = json['pumpStatus'] != null
        ? PumpStatusData.fromJson(json['pumpStatus'])
        : null;
  }

  int? number;
  String? type;
  int? capacity;
  DateTime? lastUpdated;
  DateTime? lastFull;
  WaterQualityData? waterQuality;
  PumpStatusData? pumpStatus;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['number'] = number;
    data['type'] = type;
    data['capacity'] = capacity;
    data['lastUpdated'] = lastUpdated?.toIso8601String();
    data['lastFull'] = lastFull?.toIso8601String();
    if (waterQuality != null) {
      data['waterQuality'] = waterQuality!.toJson();
    }
    if (pumpStatus != null) {
      data['pumpStatus'] = pumpStatus!.toJson();
    }
    return data;
  }
}

class WaterQualityData {
  WaterQualityData({
    this.ph,
    this.tds,
    this.temperature,
    this.hardness,
  });

  WaterQualityData.fromJson(Map<String, dynamic> json) {
    ph = json['ph'];
    tds = json['tds'];
    temperature = json['temperature'];
    hardness = json['hardness'];
  }

  double? ph;
  int? tds;
  int? temperature;
  int? hardness;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ph'] = ph;
    data['tds'] = tds;
    data['temperature'] = temperature;
    data['hardness'] = hardness;
    return data;
  }
}

class PumpStatusData {
  PumpStatusData({
    this.isOn,
    this.flowRate,
  });

  PumpStatusData.fromJson(Map<String, dynamic> json) {
    isOn = json['isOn'];
    flowRate = json['flowRate'];
  }

  bool? isOn;
  double? flowRate;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isOn'] = isOn;
    data['flowRate'] = flowRate;
    return data;
  }
}

class ROSystemData {
  ROSystemData({
    this.status,
    this.lastMaintenance,
    this.membranes,
    this.megaCharVessels,
  });

  ROSystemData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    lastMaintenance = json['lastMaintenance'];
    if (json['membranes'] != null) {
      membranes = <ComponentData>[];
      json['membranes'].forEach((v) {
        membranes!.add(ComponentData.fromJson(v));
      });
    }
    if (json['megaCharVessels'] != null) {
      megaCharVessels = <ComponentData>[];
      json['megaCharVessels'].forEach((v) {
        megaCharVessels!.add(ComponentData.fromJson(v));
      });
    }
  }

  String? status;
  String? lastMaintenance;
  List<ComponentData>? membranes;
  List<ComponentData>? megaCharVessels;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['lastMaintenance'] = lastMaintenance;
    if (membranes != null) {
      data['membranes'] = membranes!.map((v) => v.toJson()).toList();
    }
    if (megaCharVessels != null) {
      data['megaCharVessels'] =
          megaCharVessels!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ComponentData {
  ComponentData({
    this.lastReplaced,
  });

  ComponentData.fromJson(Map<String, dynamic> json) {
    lastReplaced = json['lastReplaced'];
  }

  String? lastReplaced;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lastReplaced'] = lastReplaced;
    return data;
  }
}

class MaintenanceData {
  MaintenanceData({
    this.lastBackwash,
    this.mediaLastReplaced,
    this.softenerLastReplaced,
    this.preFilterLastReplaced,
    this.postFilterLastReplaced,
    this.periods,
  });

  MaintenanceData.fromJson(Map<String, dynamic> json) {
    lastBackwash = json['lastBackwash'];
    mediaLastReplaced = json['mediaLastReplaced'];
    softenerLastReplaced = json['softenerLastReplaced'];
    preFilterLastReplaced = json['preFilterLastReplaced'];
    postFilterLastReplaced = json['postFilterLastReplaced'];
    periods = json['periods'] != null
        ? MaintenancePeriods.fromJson(json['periods'])
        : null;
  }

  String? lastBackwash;
  String? mediaLastReplaced;
  String? softenerLastReplaced;
  String? preFilterLastReplaced;
  String? postFilterLastReplaced;
  MaintenancePeriods? periods;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lastBackwash'] = lastBackwash;
    data['mediaLastReplaced'] = mediaLastReplaced;
    data['softenerLastReplaced'] = softenerLastReplaced;
    data['preFilterLastReplaced'] = preFilterLastReplaced;
    data['postFilterLastReplaced'] = postFilterLastReplaced;
    if (periods != null) {
      data['periods'] = periods!.toJson();
    }
    return data;
  }
}

class MaintenancePeriods {
  MaintenancePeriods({
    this.backwash,
    this.membrane,
    this.mediaReplacement,
    this.preFilter,
    this.postFilter,
  });

  MaintenancePeriods.fromJson(Map<String, dynamic> json) {
    backwash = json['backwash'];
    membrane = json['membrane'];
    mediaReplacement = json['mediaReplacement'];
    preFilter = json['preFilter'];
    postFilter = json['postFilter'];
  }

  int? backwash;
  int? membrane;
  int? mediaReplacement;
  int? preFilter;
  int? postFilter;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['backwash'] = backwash;
    data['membrane'] = membrane;
    data['mediaReplacement'] = mediaReplacement;
    data['preFilter'] = preFilter;
    data['postFilter'] = postFilter;
    return data;
  }
}

class EnergyPurchaseData {
  EnergyPurchaseData({
    this.date,
    this.kwh,
    this.cost,
  });

  EnergyPurchaseData.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    kwh = json['kwh'];
    cost = json['cost'];
  }

  String? date;
  int? kwh;
  double? cost;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['kwh'] = kwh;
    data['cost'] = cost;
    return data;
  }
}
