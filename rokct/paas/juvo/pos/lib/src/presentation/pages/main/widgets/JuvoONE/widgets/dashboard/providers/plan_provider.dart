import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../../models/models.dart';
import '../models/vision.dart';
import '../repository/plan_repository.dart';

class PlanProvider with ChangeNotifier {
  final PlanRepository _repository;

  Vision? _vision;
  bool _isLoading = false;
  String? _error;

  Vision? get vision => _vision;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor using dependency injection
  PlanProvider(this._repository);

  // Alternative constructor using GetIt for service location
  factory PlanProvider.fromGetIt() {
    return PlanProvider(GetIt.instance<PlanRepository>());
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Get current user data
  Future<UserData?> getCurrentUser() async {
    return LocalStorage.getUser();
  }

  Future<void> fetchPlanOnPage(String? shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getPlanOnPage(shopId);

      result.when(
        success: (vision) {
          _vision = vision;
          _clearError();
        },
        failure: (error) {
          _setError(error);
        },
      );
    } catch (e) {
      _setError('Error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Create Vision
  Future<bool> createVision(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Creating vision with data: $data');
      }

      final result = await _repository.createVision(data);

      return result.when(
        success: (vision) {
          _vision = vision;
          _clearError();
          return true;
        },
        failure: (error) {
          _setError(error);
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating vision: $e');
      }
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Vision
  Future<bool> updateVision(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateVision(uuid, data);

      return result.when(
        success: (vision) {
          _vision = vision;
          _clearError();
          return true;
        },
        failure: (error) {
          _setError(error);
          return false;
        },
      );
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Pillar
  Future<bool> createPillar(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.createPillar(data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(data['shop_id']);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Pillar
  Future<bool> updatePillar(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updatePillar(uuid, data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(_vision?.shopId);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Strategic Objective
  Future<bool> createStrategicObjective(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.createStrategicObjective(data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(data['shop_id']);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Strategic Objective
  Future<bool> updateStrategicObjective(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateStrategicObjective(uuid, data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(_vision?.shopId);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create KPI
  Future<bool> createKpi(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.createKpi(data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(data['shop_id']);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update KPI
  Future<bool> updateKpi(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateKpi(uuid, data);

      final success = result.when(
        success: (_) => true,
        failure: (error) {
          _setError(error);
          return false;
        },
      );

      if (success) {
        await fetchPlanOnPage(_vision?.shopId);
      }

      return success;
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
