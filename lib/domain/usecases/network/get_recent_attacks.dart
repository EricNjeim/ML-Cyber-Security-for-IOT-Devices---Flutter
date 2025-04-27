import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';

/// Use case to get recent attack logs
class GetRecentAttacks {
  final NetworkTrafficRepository repository;

  GetRecentAttacks(this.repository);

  /// Call the repository to get recent attack logs
  Future<Result<List<NetworkTraffic>>> call() async {
    try {
      final attacks = await repository.getRecentAttacks();
      return Result.success(attacks);
    } on ServerException {
      return Result.failure(const ServerFailure());
    } on UnauthorizedException {
      return Result.failure(const AuthenticationFailure());
    } on NetworkException {
      return Result.failure(const NetworkFailure());
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
