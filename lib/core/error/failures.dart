abstract class Failure {
  final String message;

  const Failure({this.message = 'An unexpected error occurred'});
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'A server error occurred'});
}

class NetworkFailure extends Failure {
  const NetworkFailure(
      {super.message =
          'A network error occurred, please check your connection'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'A cache error occurred'});
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({super.message = 'Authentication failed'});
}
