import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

/// Use case to get all IoT devices
class GetDevices {
  final DeviceRepository repository;

  GetDevices(this.repository);

  /// Call the repository to get all devices
  Future<Result<List<Device>>> call() async {
    try {
      final devices = await repository.getDevices();
      return Result.success(devices);
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
