import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/todo_task.dart';
import '../repository/task_repository.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository;

  List<TodoTask> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<TodoTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor using dependency injection
  TaskProvider(this._repository);

  // Alternative constructor using GetIt for service location
  factory TaskProvider.fromGetIt() {
    return TaskProvider(GetIt.instance<TaskRepository>());
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchTasks(
      String? shopId, {
        String? kpiId,
        String? objectiveId,
        String? appId,
      }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchTasks(
        shopId,
        kpiId: kpiId,
        objectiveId: objectiveId,
        appId: appId,
      );

      result.when(
        success: (tasks) {
          _tasks = tasks;
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

  Future<TodoTask?> getTask(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getTask(uuid);

      return result.when(
        success: (task) {
          _clearError();
          return task;
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

  Future<bool> createTask(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Creating task with data: $data');
      }

      final result = await _repository.createTask(data);

      return result.when(
        success: (task) {
          // Add the new task to our list
          _tasks.add(task);
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
        print('Error creating task: $e');
      }
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateTask(uuid, data);

      return result.when(
        success: (updatedTask) {
          // Update the task in our local list
          final index = _tasks.indexWhere((task) => task.uuid == uuid);
          if (index != -1) {
            _tasks[index] = updatedTask;
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

  Future<bool> deleteTask(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deleteTask(uuid);

      return result.when(
        success: (_) {
          // Remove the task from our local list
          _tasks.removeWhere((task) => task.uuid == uuid);
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
}
