import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

/// Use case to ping a device to check connectivity
class PingDevice {
  final DeviceRepository repository;

  PingDevice(this.repository);

  /// Call the repository to ping a device
  Future<Result<PingResult>> call(String ipAddress) async {
    try {
      return await repository.pingDevice(ipAddress);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to ping device: ${e.toString()}'),
      );
    }
  }
}
