import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';

/// Use case to refresh the token via automatic re-login with stored credentials
class LoginForRefresh {
  final AuthRepository repository;

  LoginForRefresh(this.repository);

  /// Attempt to refresh the token using stored credentials
  Future<Result<bool>> call() async {
    // Call getValidToken which will refresh if needed
    final tokenResult = await repository.refreshToken();

    return tokenResult.fold(
      (_) => Result.success(true), // If we get a token, success = true
      (failure) => Result.failure(failure), // Pass through the failure
    );
  }
}
