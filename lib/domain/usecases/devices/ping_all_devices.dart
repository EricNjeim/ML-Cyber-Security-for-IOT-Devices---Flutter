import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

/// Use case to ping all devices in the network
class PingAllDevices {
  final DeviceRepository repository;

  PingAllDevices(this.repository);

  /// Call the repository to ping all devices
  Future<Result<Map<String, PingResult>>> call() async {
    try {
      return await repository.pingAllDevices();
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to ping all devices: ${e.toString()}'),
      );
    }
  }
}
