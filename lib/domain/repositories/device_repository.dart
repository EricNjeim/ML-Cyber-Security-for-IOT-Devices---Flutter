import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/models/port_scan_result.dart';

/// Interface for device operations
abstract class DeviceRepository {
  /// Get all IoT devices
  Future<List<Device>> getDevices();

  /// Get a specific device by ID
  Future<Device?> getDeviceById(String id);

  /// Add a new device
  Future<Result<Device>> addDevice(Device device);

  /// Update a device
  Future<Result<Device>> updateDevice(Device device);

  /// Remove a device
  Future<Result<bool>> removeDevice(String id);

  /// Ping a device to check connectivity
  Future<Result<PingResult>> pingDevice(String ipAddress);

  /// Ping all devices in the network
  Future<Result<Map<String, PingResult>>> pingAllDevices();

  /// Scan ports on a device
  Future<Result<PortScanResult>> scanDevicePorts(String ipAddress);
}

/// Result of a ping operation
class PingResult {
  final bool isReachable;
  final LatencyInfo? latency;
  final String? packetLoss;
  final String? error;
  final String status;

  PingResult({
    required this.isReachable,
    this.latency,
    this.packetLoss,
    this.error,
    this.status = 'unknown',
  });
}

/// Detailed latency information
class LatencyInfo {
  final double min;
  final double max;
  final double avg;

  LatencyInfo({
    required this.min,
    required this.max,
    required this.avg,
  });
}
