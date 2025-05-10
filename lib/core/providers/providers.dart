import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';
import 'dart:async';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/domain/models/attack_frequency.dart';
import 'package:iotframework/domain/models/daily_attack_frequency.dart';
import 'package:iotframework/domain/models/port_scan_result.dart';

/// Provider for recent network attacks
final recentAttacksProvider =
    FutureProvider<Result<List<NetworkTraffic>>>((ref) async {
  try {
    final repo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
    final attacks = await repo.getRecentAttacks();
    return Result.success(attacks);
  } catch (e) {
    return Result.failure(ServerFailure(message: e.toString()));
  }
});

/// Provider for today's attacks with auto-refresh
final todayAttacksProvider =
    StreamProvider<Result<List<NetworkTraffic>>>((ref) {
  final networkRepo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
  final controller = StreamController<Result<List<NetworkTraffic>>>();

  // Initial fetch
  _fetchTodayAttacks(networkRepo, controller);

  // Set up periodic timer for refresh every 10 seconds
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    _fetchTodayAttacks(networkRepo, controller);
  });

  // Clean up when provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider for week's attacks with auto-refresh
final weekAttacksProvider = StreamProvider<Result<List<NetworkTraffic>>>((ref) {
  final networkRepo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
  final controller = StreamController<Result<List<NetworkTraffic>>>();

  // Initial fetch
  _fetchWeekAttacks(networkRepo, controller);

  // Set up periodic timer for refresh every 10 seconds
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    _fetchWeekAttacks(networkRepo, controller);
  });

  // Clean up when provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider for month's attacks with auto-refresh
final monthAttacksProvider =
    StreamProvider<Result<List<NetworkTraffic>>>((ref) {
  final networkRepo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
  final controller = StreamController<Result<List<NetworkTraffic>>>();

  // Initial fetch
  _fetchMonthAttacks(networkRepo, controller);

  // Set up periodic timer for refresh every 10 seconds
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    _fetchMonthAttacks(networkRepo, controller);
  });

  // Clean up when provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// Helper function to fetch today's attacks
void _fetchTodayAttacks(NetworkTrafficRepository repo,
    StreamController<Result<List<NetworkTraffic>>> controller) async {
  try {
    // Use dedicated method for today's attacks
    final response = await repo.getTodayAttacks();
    controller.add(Result.success(response));
  } catch (e) {
    controller.add(Result.failure(ServerFailure(message: e.toString())));
  }
}

// Helper function to fetch week's attacks
void _fetchWeekAttacks(NetworkTrafficRepository repo,
    StreamController<Result<List<NetworkTraffic>>> controller) async {
  try {
    // Use dedicated method for week's attacks
    final response = await repo.getWeekAttacks();
    controller.add(Result.success(response));
  } catch (e) {
    controller.add(Result.failure(ServerFailure(message: e.toString())));
  }
}

// Helper function to fetch month's attacks
void _fetchMonthAttacks(NetworkTrafficRepository repo,
    StreamController<Result<List<NetworkTraffic>>> controller) async {
  try {
    // Use dedicated method for month's attacks
    final response = await repo.getMonthAttacks();
    controller.add(Result.success(response));
  } catch (e) {
    controller.add(Result.failure(ServerFailure(message: e.toString())));
  }
}

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

/// Provider for scanning device ports
final portScanProvider = FutureProvider.family<Result<PortScanResult>, String>(
    (ref, ipAddress) async {
  final scanDevicePorts = ref.read(ServiceLocator.scanDevicePortsProvider);
  return await scanDevicePorts(ipAddress);
});

/// Provider for attack frequency data
final attackFrequencyProvider =
    FutureProvider<Result<AttackFrequency>>((ref) async {
  try {
    final repo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
    final frequency = await repo.getAttackFrequency();
    return Result.success(frequency);
  } catch (e) {
    return Result.failure(ServerFailure(message: e.toString()));
  }
});

/// Provider for daily attack frequency data
final dailyAttackFrequencyProvider =
    FutureProvider<Result<DailyAttackFrequency>>((ref) async {
  try {
    final repo = ref.read(ServiceLocator.networkTrafficRepositoryProvider);
    final frequency = await repo.getDailyAttackFrequency();
    return Result.success(frequency);
  } catch (e) {
    return Result.failure(ServerFailure(message: e.toString()));
  }
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
