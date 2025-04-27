import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/network_traffic.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';
import 'package:iotframework/core/error/exceptions.dart';

class GetNetworkTrafficLogs {
  final NetworkTrafficRepository repository;

  GetNetworkTrafficLogs(this.repository);

  Future<Result<List<NetworkTraffic>>> call() async {
    try {
      final logs = await repository.getNetworkTrafficLogs();
      return Result.success(logs.cast<NetworkTraffic>());
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
