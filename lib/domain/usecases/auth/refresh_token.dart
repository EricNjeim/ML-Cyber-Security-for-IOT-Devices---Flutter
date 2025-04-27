import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';

/// Use case to refresh the authentication token
class RefreshToken {
  final AuthRepository repository;

  RefreshToken(this.repository);

  /// Refresh the token using the stored refresh token
  Future<Result<bool>> call() async {
    return await repository.refreshToken();
  }
}
