import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../models/roadmap_version.dart';
import '../repository/roadmap_repository.dart';

class RoadmapProvider with ChangeNotifier {
  final RoadmapRepository _repository;

  List<RoadmapVersion> _versions = [];
  bool _isLoading = false;
  String? _error;

  List<RoadmapVersion> get versions => _versions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor using dependency injection
  RoadmapProvider(this._repository);

  // Alternative constructor using GetIt for service location
  factory RoadmapProvider.fromGetIt() {
    return RoadmapProvider(GetIt.instance<RoadmapRepository>());
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchRoadmapVersions(String? appId) async {
    if (appId == null) {
      _setError('App ID is required');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchRoadmapVersions(appId);

      result.when(
        success: (versions) {
          _versions = versions;
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

  Future<RoadmapVersion?> getRoadmapVersion(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getRoadmapVersion(uuid);

      return result.when(
        success: (version) {
          _clearError();
          return version;
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

  Future<bool> createRoadmapVersion(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Creating roadmap version with data: $data');
      }

      final result = await _repository.createRoadmapVersion(data);

      return result.when(
        success: (version) {
          // Add the new version to our list and re-sort
          _versions.add(version);
          _versions.sort((a, b) => _compareVersions(b.versionNumber, a.versionNumber));
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
        print('Error creating roadmap version: $e');
      }
      _setError('Error: ${e.toString()}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRoadmapVersion(String uuid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateRoadmapVersion(uuid, data);

      return result.when(
        success: (updatedVersion) {
          // Update the version in our local list
          final index = _versions.indexWhere((version) => version.uuid == uuid);
          if (index != -1) {
            _versions[index] = updatedVersion;
            // Re-sort if version number changed
            _versions.sort((a, b) => _compareVersions(b.versionNumber, a.versionNumber));
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

  Future<bool> deleteRoadmapVersion(String uuid, String appId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.deleteRoadmapVersion(uuid);

      return result.when(
        success: (_) {
          // Remove the version from our local list
          _versions.removeWhere((version) => version.uuid == uuid);
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

  Future<void> fetchVersionsByStatus(String appId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchVersionsByStatus(appId, status);

      result.when(
        success: (versions) {
          _versions = versions;
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

  // Compare version numbers (e.g., "1.2.3" > "1.2.0")
  int _compareVersions(String version1, String version2) {
    final List<int> v1Parts = version1.split('.').map(int.parse).toList();
    final List<int> v2Parts = version2.split('.').map(int.parse).toList();

    // Pad shorter version with zeros
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    // Compare each segment
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }

    return 0; // Versions are equal
  }
}
