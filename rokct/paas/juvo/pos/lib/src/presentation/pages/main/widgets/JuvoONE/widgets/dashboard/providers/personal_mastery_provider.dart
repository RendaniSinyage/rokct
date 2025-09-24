import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/personal_mastery_goal.dart';
import '../repository/personal_mastery_repository.dart';

class PersonalMasteryProvider with ChangeNotifier {
  final PersonalMasteryRepository _repository;

  List<PersonalMasteryGoal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<PersonalMasteryGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor using dependency injection
  PersonalMasteryProvider(this._repository);

  // Alternative constructor using GetIt for service location
  factory PersonalMasteryProvider.fromGetIt() {
    return PersonalMasteryProvider(GetIt.instance<PersonalMasteryRepository>());
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchPersonalMasteryGoals(int? userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchPersonalMasteryGoals(userId);

      result.when(
        success: (goals) {
          _goals = goals;
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

  Future<PersonalMasteryGoal?> getPersonalMasteryGoal(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getPersonalMasteryGoal(uuid);

      return result.when(
        success: (goal) {
          _clearError();
          return goal;
        },
        failure: (error) {
          _setError(error);
          return null;
        },
      );
    } catch (e) {
      _setError('Error: ${e.toString()}');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPersonalMasteryGoal(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Creating personal mastery goal with data: $data');
      }

      final result = await _repository.createPersonalMasteryGoal(data);

      return result.when(
        success: (goal) {
          // Add the new goal to our list
          _goals.add(goal);
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
        print('Error creating personal mastery goal: $e');
      }
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePersonalMasteryGoal(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updatePersonalMasteryGoal(uuid, data);

      return result.when(
        success: (updatedGoal) {
          // Update the goal in our local list
          final index = _goals.indexWhere((goal) => goal.uuid == uuid);
          if (index != -1) {
            _goals[index] = updatedGoal;
          }
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

  Future<bool> deletePersonalMasteryGoal(String uuid, int? userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deletePersonalMasteryGoal(uuid);

      return result.when(
        success: (_) {
          // Remove the goal from our local list
          _goals.removeWhere((goal) => goal.uuid == uuid);
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

  Future<void> fetchGoalsByArea(int? userId, String area) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchGoalsByArea(userId, area);

      result.when(
        success: (goals) {
          _goals = goals;
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

  Future<void> fetchGoalsByStatus(int? userId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchGoalsByStatus(userId, status);

      result.when(
        success: (goals) {
          _goals = goals;
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
}
