import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../models/data/tank_models.dart';
import '../repository/tanks_api.dart';
import '../ro_system_efficiency.dart';

class PumpRuntimeManager {
  static const String _storageKey = 'pump_runtime_data';
  static const Duration _updateInterval = Duration(seconds: 30);

  Timer? _updateTimer;
  final void Function() onWaterLevelUpdate;
  final List<Tank> _tanks;
  final double Function(Tank) calculateWaterLevel;  // Add this line

  PumpRuntimeManager({
    required this.onWaterLevelUpdate,
    required List<Tank> tanks,
    required this.calculateWaterLevel,  // Add this line
  }) : _tanks = tanks {
    _restorePumpStates();
  }

  Future<void> _restorePumpStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pumpKeys = prefs.getKeys().where((key) => key.startsWith(_storageKey));

      for (final key in pumpKeys) {
        final pumpDataString = prefs.getString(key);
        if (pumpDataString != null) {
          final pumpData = jsonDecode(pumpDataString);
          if (pumpData['isRunning'] == true) {
            final tankId = int.parse(key.split('_').last);
            _startUpdateTimer(tankId, pumpData['flowRate']);
          }
        }
      }
    } catch (e) {
      print('Error restoring pump states: $e');
    }
  }

  Future<void> startPump(int tankId, double flowRate, double currentLevel) async {
    final pumpData = {
      'startTime': DateTime.now().toIso8601String(),
      'flowRate': flowRate,
      'initialLevel': currentLevel,
      'isRunning': true
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_storageKey}_$tankId', jsonEncode(pumpData));

    _startUpdateTimer(tankId, flowRate);
  }

  Future<void> stopPump(int tankId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_storageKey}_$tankId');
    _updateTimer?.cancel();
  }

  void _startUpdateTimer(int tankId, double flowRate) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      _updateWaterLevel(tankId, flowRate);
    });
  }

  Future<void> _updateWaterLevel(int tankId, double flowRate) async {
    final prefs = await SharedPreferences.getInstance();
    final pumpDataString = prefs.getString('${_storageKey}_$tankId');

    if (pumpDataString == null) {
      _updateTimer?.cancel();
      return;
    }

    try {
      final pumpData = jsonDecode(pumpDataString);
      final startTime = DateTime.parse(pumpData['startTime']);
      final initialLevel = pumpData['initialLevel'] as double;

      // Calculate minutes elapsed and water used from raw tank
      final minutesElapsed = DateTime.now().difference(startTime).inMinutes;
      final litersUsed = minutesElapsed * flowRate;

      // Get tanks
      final rawTank = _tanks.firstWhere((tank) => tank.type == TankType.raw);
      final purifiedTank = _tanks.firstWhere((tank) => tank.type == TankType.purified);

      // Get current RO system efficiency
      final systemEfficiency = await ROSystemEfficiency.calculateSystemEfficiency();
      final efficiencyPercentage = systemEfficiency / 100;

      // Update raw water tank level (decreasing)
      final rawTankCurrentLevel = initialLevel - litersUsed;
      if (rawTankCurrentLevel <= 0) {
        await TankApiService.updatePumpOnlyStatus(tankId, false);
        await stopPump(tankId);
        await TankApiService.updateTankStatus(rawTank.id!, TankStatus.empty);
        return;
      }
      await TankApiService.updateTankStatus(rawTank.id!, rawTankCurrentLevel <= 0.05 * rawTank.capacity ? TankStatus.empty : TankStatus.quarterEmpty);

      // For purified tank, calculate water gained from RO
      final currentLevelWithUsage = calculateWaterLevel(purifiedTank);  // Includes usage reduction
      final purifiedWaterGained = litersUsed * efficiencyPercentage;
      final newPurifiedLevel = currentLevelWithUsage + purifiedWaterGained;

      // If purified tank becomes completely full from RO input
      if (newPurifiedLevel >= purifiedTank.capacity) {
        await TankApiService.updatePumpOnlyStatus(tankId, false);
        await stopPump(tankId);
        await TankApiService.updateTankStatus(purifiedTank.id!, TankStatus.full);
        final updatedTank = purifiedTank;
        updatedTank.lastFull = DateTime.now();
        await TankApiService.updateTank(updatedTank);
        return;
      }

      // Update purified tank status based on level without updating last_full
      if (newPurifiedLevel <= 0) {
        await TankApiService.updateTankStatus(purifiedTank.id!, TankStatus.empty);
      } else if (newPurifiedLevel <= 0.25 * purifiedTank.capacity) {
        await TankApiService.updateTankStatus(purifiedTank.id!, TankStatus.quarterEmpty);
      } else if (newPurifiedLevel <= 0.5 * purifiedTank.capacity) {
        await TankApiService.updateTankStatus(purifiedTank.id!, TankStatus.halfEmpty);
      }

      onWaterLevelUpdate();
    } catch (e) {
      print('Error updating water level: $e');
    }
  }

  Future<void> _updateTankStatus(int tankId, double currentLevel, double capacity) async {
    final levelPercentage = (currentLevel / capacity) * 100;

    TankStatus newStatus;
    if (levelPercentage <= 5) {
      newStatus = TankStatus.empty;
    } else if (levelPercentage <= 25) {
      newStatus = TankStatus.quarterEmpty;
    } else if (levelPercentage <= 50) {
      newStatus = TankStatus.halfEmpty;
    } else {
      newStatus = TankStatus.full;
    }

    await TankApiService.updateTankStatus(tankId, newStatus);
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
