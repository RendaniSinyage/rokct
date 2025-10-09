import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../roSystem/models/data/energy_data.dart';
import '../../roSystem/models/data/ro_system_model.dart';
import '../../roSystem/models/data/tank_models.dart';

// Provider to cache tanks data
final tanksDataProvider = StateProvider<Map<int, List<Tank>>>((ref) => {});

// Provider to cache RO system data
final roSystemDataProvider = StateProvider<Map<int, ROSystem?>>((ref) => {});

// Provider to cache energy consumption data
final energyDataProvider = StateProvider<Map<int, EnergyConsumptionData?>>((ref) => {});

