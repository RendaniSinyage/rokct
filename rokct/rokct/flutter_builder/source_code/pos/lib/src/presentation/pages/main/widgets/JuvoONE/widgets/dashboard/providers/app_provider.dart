// app_provider.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/app.dart';
import '../repository/app_repository.dart';

class AppProvider with ChangeNotifier {
  final AppRepository _repository;

  List<App> _apps = [];
  bool _isLoading = false;
  String? _error;

  List<App> get apps => _apps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor using dependency injection
  AppProvider(this._repository);

  // Alternative constructor using GetIt for service location
  factory AppProvider.fromGetIt() {
    return AppProvider(GetIt.instance<AppRepository>());
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchApps(String? shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchApps(shopId);

      result.when(
        success: (apps) {
          _apps = apps;
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

  Future<App?> getApp(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getApp(uuid);

      return result.when(
        success: (app) {
          _clearError();
          return app;
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

  Future<bool> createApp(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Creating app with data: $data');
      }

      final result = await _repository.createApp(data);

      return result.when(
        success: (app) {
          // Add the new app to our list
          _apps.add(app);
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
        print('Error creating app: $e');
      }
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApp(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateApp(uuid, data);

      return result.when(
        success: (updatedApp) {
          // Update the app in our local list
          final index = _apps.indexWhere((app) => app.uuid == uuid);
          if (index != -1) {
            _apps[index] = updatedApp;
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

  Future<bool> deleteApp(String uuid, int? shopId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deleteApp(uuid);

      return result.when(
        success: (_) {
          // Remove the app from our local list
          _apps.removeWhere((app) => app.uuid == uuid);
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
