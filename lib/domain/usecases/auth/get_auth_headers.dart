import 'package:iotframework/domain/repositories/auth_repository.dart';

/// Use case to get authentication headers for API requests
class GetAuthHeaders {
  final AuthRepository repository;

  GetAuthHeaders(this.repository);

  /// Get authentication headers from the repository
  Future<Map<String, String>> call() => repository.getAuthHeaders();
}
