import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';

/// Provider for recent network attacks
final recentAttacksProvider =
    FutureProvider<Result<List<NetworkTraffic>>>((ref) async {
  final getRecentAttacks = ref.read(ServiceLocator.getRecentAttacksProvider);
  return await getRecentAttacks();
});

/// Provider for network traffic logs
final networkTrafficLogsProvider =
    FutureProvider<Result<List<NetworkTraffic>>>((ref) async {
  final getNetworkTrafficLogs =
      ref.read(ServiceLocator.getNetworkTrafficLogsProvider);
  return await getNetworkTrafficLogs();
});

/// Provider for devices list
final devicesProvider = FutureProvider<Result<List<Device>>>((ref) async {
  final getDevices = ref.read(ServiceLocator.getDevicesProvider);
  return await getDevices();
});

/// Provider for ping results
final pingResultProvider =
    FutureProvider.family<Result<PingResult>, String>((ref, ipAddress) async {
  final pingDevice = ref.read(ServiceLocator.pingDeviceProvider);
  return await pingDevice(ipAddress);
});

/// Provider for pinging all devices
final pingAllDevicesProvider =
    FutureProvider<Result<Map<String, PingResult>>>((ref) async {
  final pingAllDevices = ref.read(ServiceLocator.pingAllDevicesProvider);
  return await pingAllDevices();
});

// Direct repository providers (commented out as they're not needed with ServiceLocator)
/*
final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => ref.read(ServiceLocator.deviceRepositoryProvider),
);

final networkTrafficRepositoryProvider = Provider<NetworkTrafficRepository>(
  (ref) => ref.read(ServiceLocator.networkTrafficRepositoryProvider),
);
*/
