import 'dart:io';
import 'package:dio/dio.dart';
import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/data/models/device_model.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/models/port_scan_result.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';

/// Implementation of [DeviceRepository]
class DeviceRepositoryImpl implements DeviceRepository {
  final NetworkService _networkService;

  DeviceRepositoryImpl({
    required NetworkService networkService,
  }) : _networkService = networkService;

  @override
  Future<List<Device>> getDevices() async {
    try {
      final response = await _networkService.get('/devices');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both response formats
        if (data is Map<String, dynamic> && data.containsKey('devices')) {
          // New format with count and devices
          final devicesList = data['devices'] as List;
          return devicesList.map((item) => DeviceModel.fromJson(item)).toList();
        } else if (data is List) {
          // Old format with direct list
          return data.map((item) => DeviceModel.fromJson(item)).toList();
        }

        return [];
      } else {
        throw ServerException();
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<Device?> getDeviceById(String id) async {
    try {
      final response = await _networkService.get('/devices/$id');

      if (response.statusCode == 200) {
        return DeviceModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerException();
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<Result<Device>> addDevice(Device device) async {
    try {
      final deviceModel = device as DeviceModel;
      final response = await _networkService.post(
        '/devices',
        data: deviceModel.toJson(),
      );

      if (response.statusCode == 201) {
        return Result.success(DeviceModel.fromJson(response.data));
      } else {
        return Result.failure(
          ServerFailure(message: 'Failed to add device'),
        );
      }
    } on UnauthorizedException {
      return Result.failure(const AuthenticationFailure());
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Result<Device>> updateDevice(Device device) async {
    try {
      final deviceModel = device as DeviceModel;
      final response = await _networkService.put(
        '/devices/${device.id}',
        data: deviceModel.toJson(),
      );

      if (response.statusCode == 200) {
        return Result.success(DeviceModel.fromJson(response.data));
      } else {
        return Result.failure(
          ServerFailure(message: 'Failed to update device'),
        );
      }
    } on UnauthorizedException {
      return Result.failure(const AuthenticationFailure());
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Result<bool>> removeDevice(String id) async {
    try {
      final response = await _networkService.delete('/devices/$id');

      if (response.statusCode == 200) {
        return Result.success(true);
      } else {
        return Result.failure(
          ServerFailure(message: 'Failed to remove device'),
        );
      }
    } on UnauthorizedException {
      return Result.failure(const AuthenticationFailure());
    } catch (e) {
      return Result.failure(
        ServerFailure(message: e.toString()),
      );
    }
  }

  @override
  Future<Result<PingResult>> pingDevice(String ipAddress) async {
    try {
      // Try the dedicated ping endpoint first
      try {
        final response = await _networkService.get('/devices/ping/$ipAddress');

        if (response.statusCode == 200) {
          final data = response.data;
          return Result.success(_parsePingResult(data));
        }
      } catch (e) {
        // Fallback to the device-specific ping if available
        try {
          // Find device id by IP address
          final devices = await getDevices();
          Device? deviceWithMatchingIp;
          for (final device in devices) {
            if (device.ipAddress == ipAddress) {
              deviceWithMatchingIp = device;
              break;
            }
          }

          if (deviceWithMatchingIp != null) {
            final response = await _networkService
                .get('/devices/${deviceWithMatchingIp.id}/ping');

            if (response.statusCode == 200) {
              final data = response.data;
              return Result.success(_parsePingResult(data));
            }
          }
        } catch (_) {
          // Continue to client-side ping
        }
      }

      // Client-side ping fallback
      final stopwatch = Stopwatch()..start();
      final result = await _pingDeviceLocally(ipAddress);
      stopwatch.stop();

      if (result) {
        return Result.success(
          PingResult(
            isReachable: true,
            latency: LatencyInfo(
              min: stopwatch.elapsedMilliseconds.toDouble(),
              max: stopwatch.elapsedMilliseconds.toDouble(),
              avg: stopwatch.elapsedMilliseconds.toDouble(),
            ),
            status: 'online',
            packetLoss: '0%',
          ),
        );
      } else {
        return Result.success(
          PingResult(
            isReachable: false,
            error: 'Device is not reachable',
            status: 'offline',
            packetLoss: '100%',
          ),
        );
      }
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to ping device: ${e.toString()}'),
      );
    }
  }

  /// Parse ping response from server
  PingResult _parsePingResult(Map<String, dynamic> data) {
    // Handle ping-all format for a single device
    if (data.containsKey('device') && data.containsKey('ping_result')) {
      final pingResult = data['ping_result'];
      final status = pingResult['status'] as String? ?? 'unknown';
      final isReachable = status == 'online';

      // Parse latency info if available
      LatencyInfo? latencyInfo;
      if (pingResult.containsKey('latency') && pingResult['latency'] != null) {
        final latency = pingResult['latency'];
        latencyInfo = LatencyInfo(
          min: (latency['min'] as num?)?.toDouble() ?? 0,
          max: (latency['max'] as num?)?.toDouble() ?? 0,
          avg: (latency['avg'] as num?)?.toDouble() ?? 0,
        );
      }

      return PingResult(
        isReachable: isReachable,
        latency: latencyInfo,
        packetLoss: pingResult['packet_loss'],
        status: status,
        error: isReachable ? null : 'Device is not reachable',
      );
    }

    // Legacy format or simple ping format
    final bool isReachable = data['reachable'] ?? false;
    final int? latencyMs = data['latency'];

    return PingResult(
      isReachable: isReachable,
      latency: latencyMs != null
          ? LatencyInfo(
              min: latencyMs.toDouble(),
              max: latencyMs.toDouble(),
              avg: latencyMs.toDouble(),
            )
          : null,
      status: isReachable ? 'online' : 'offline',
      packetLoss: isReachable ? '0%' : '100%',
      error: data['error'],
    );
  }

  /// Ping all devices in the network
  @override
  Future<Result<Map<String, PingResult>>> pingAllDevices() async {
    try {
      // Create options with extended timeout for this operation
      final options = Options(
        receiveTimeout:
            const Duration(seconds: 60), // Increase from 10 to 60 seconds
        sendTimeout: const Duration(seconds: 60),
      );

      final response = await _networkService.get(
        '/devices/ping-all',
        options: options, // Pass custom options
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        final Map<String, PingResult> results = {};

        // Handle new response format
        if (responseData.containsKey('results')) {
          final resultsList = responseData['results'] as List;

          for (final item in resultsList) {
            if (item.containsKey('device') && item.containsKey('ping_result')) {
              final device = item['device'];
              final ipAddress = device['ip_address'] as String;

              final pingResult = _parsePingResult(item);
              results[ipAddress] = pingResult;
            }
          }
        } else {
          // Legacy format - direct mapping
          responseData.forEach((ip, pingData) {
            if (ip != 'count') {
              // Skip the count field
              results[ip] = _parsePingResult(pingData);
            }
          });
        }

        return Result.success(results);
      } else {
        return Result.failure(
          ServerFailure(message: 'Failed to ping all devices'),
        );
      }
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to ping all devices: ${e.toString()}'),
      );
    }
  }

  /// Perform a local ping to the device
  Future<bool> _pingDeviceLocally(String ipAddress) async {
    try {
      // Try ICMP ping first using Socket to check if port is open
      // Most IoT devices have port 80 or 443 open
      final socket = await Socket.connect(ipAddress, 80,
              timeout: const Duration(seconds: 3))
          .catchError((_) => null);

      if (socket != null) {
        await socket.close();
        return true;
      }

      // Try HTTPS port if HTTP failed
      final httpsSocket = await Socket.connect(ipAddress, 443,
              timeout: const Duration(seconds: 3))
          .catchError((_) => null);

      if (httpsSocket != null) {
        await httpsSocket.close();
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Perform a port scan on a device
  @override
  Future<Result<PortScanResult>> scanDevicePorts(String ipAddress) async {
    try {
      // Find device id by IP address
      final devices = await getDevices();
      Device? deviceWithMatchingIp;
      for (final device in devices) {
        if (device.ipAddress == ipAddress) {
          deviceWithMatchingIp = device;
          break;
        }
      }

      if (deviceWithMatchingIp != null) {
        // Use device ID endpoint
        final response = await _networkService.get(
          '/devices/${deviceWithMatchingIp.id}/scan',
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          return Result.success(PortScanResult.fromJson(data));
        } else {
          return Result.failure(
            ServerFailure(message: 'Failed to scan ports on device'),
          );
        }
      } else {
        return Result.failure(
          ServerFailure(message: 'Device not found with IP: $ipAddress'),
        );
      }
    } on UnauthorizedException {
      return Result.failure(const AuthenticationFailure());
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to scan ports: ${e.toString()}'),
      );
    }
  }
}
