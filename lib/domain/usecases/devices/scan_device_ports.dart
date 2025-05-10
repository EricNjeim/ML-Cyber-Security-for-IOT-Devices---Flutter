import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/port_scan_result.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

/// Use case to scan ports on a device
class ScanDevicePorts {
  final DeviceRepository repository;

  ScanDevicePorts(this.repository);

  /// Call the repository to scan ports on a device
  Future<Result<PortScanResult>> call(String ipAddress) async {
    try {
      return await repository.scanDevicePorts(ipAddress);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to scan device ports: ${e.toString()}'),
      );
    }
  }
}
