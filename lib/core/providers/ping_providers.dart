import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:flutter/foundation.dart';

/// Provider for pinging a single device
final pingDeviceProvider = FutureProvider.family<Result<PingResult>, String>(
  (ref, ipAddress) async {
    final pingDevice = ref.read(ServiceLocator.pingDeviceProvider);
    return await pingDevice(ipAddress);
  },
);

/// Provider for pinging all devices
final pingAllDevicesProvider = FutureProvider<Result<Map<String, PingResult>>>(
  (ref) async {
    final pingAllDevices = ref.read(ServiceLocator.pingAllDevicesProvider);
    return await pingAllDevices();
  },
);

/// Provider for the current ping status of a specific device
final devicePingStatusProvider = StateProvider.family<PingStatus, String>(
  (ref, deviceId) => PingStatus.unknown,
);

/// Provider for the ping status of all devices
final allDevicesPingStatusProvider = StateProvider<Map<String, PingStatus>>(
  (ref) => {},
);

/// Provider that automatically pings all devices and updates their statuses
final devicePingMonitorProvider = Provider<void>(
  (ref) {
    // This can be expanded to set up periodic pinging
    final pingAllDevicesFuture = ref.watch(pingAllDevicesProvider.future);

    pingAllDevicesFuture.then((result) {
      if (result.isSuccess) {
        final pingResults = result.value;
        final statuses = <String, PingStatus>{};

        for (final entry in pingResults.entries) {
          final deviceId = entry.key;
          final pingResult = entry.value;

          final status =
              pingResult.isReachable ? PingStatus.online : PingStatus.offline;
          statuses[deviceId] = status;
          ref.read(devicePingStatusProvider(deviceId).notifier).state = status;
        }

        ref.read(allDevicesPingStatusProvider.notifier).state = statuses;
      } else {
        debugPrint("Failed to ping devices: ${result.failure}");
      }
    });
  },
);

/// Enum representing the ping status of a device
enum PingStatus {
  online,
  offline,
  timeout,
  unknown,
}

extension PingStatusExtension on PingStatus {
  bool get isOnline => this == PingStatus.online;
  bool get isOffline => this == PingStatus.offline;
  bool get isTimeout => this == PingStatus.timeout;
  bool get isUnknown => this == PingStatus.unknown;
}
