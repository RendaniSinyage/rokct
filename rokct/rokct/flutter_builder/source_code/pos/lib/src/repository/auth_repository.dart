import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';

abstract class AuthRepository {
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<void>> updateFirebaseToken(String? token);
}

