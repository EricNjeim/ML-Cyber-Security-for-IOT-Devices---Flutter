import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';

/// Login use case for authenticating users
class Login {
  final AuthRepository repository;

  Login(this.repository);

  /// Call the login method with the [email] and [password]
  Future<Result<Map<String, dynamic>>> call(
      String email, String password) async {
    return await repository.login(email, password);
  }
}
