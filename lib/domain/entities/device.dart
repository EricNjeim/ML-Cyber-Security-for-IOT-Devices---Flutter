import 'package:flutter/material.dart';

/// Represents an IoT device in the system
class Device {
  final String id;
  final String name;
  final String ipAddress;
  final String macAddress;
  final DeviceType type;
  final DeviceStatus status;
  final DateTime lastSeen;
  final Map<String, dynamic>? metadata;

  Device({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    required this.type,
    required this.status,
    required this.lastSeen,
    this.metadata,
  });
}

/// Types of IoT devices
enum DeviceType { camera, sensor, thermostat, lightBulb, switch_, lock, other }

/// Connection status of devices
enum DeviceStatus { online, offline, warning, compromised }

/// Extension to get display names for device types
extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.camera:
        return 'Camera';
      case DeviceType.sensor:
        return 'Sensor';
      case DeviceType.thermostat:
        return 'Thermostat';
      case DeviceType.lightBulb:
        return 'Light Bulb';
      case DeviceType.switch_:
        return 'Switch';
      case DeviceType.lock:
        return 'Lock';
      case DeviceType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.sensor:
        return Icons.sensors;
      case DeviceType.thermostat:
        return Icons.thermostat;
      case DeviceType.lightBulb:
        return Icons.lightbulb;
      case DeviceType.switch_:
        return Icons.toggle_on;
      case DeviceType.lock:
        return Icons.lock;
      case DeviceType.other:
        return Icons.devices_other;
    }
  }
}

/// Extension to get display information for device status
extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
      case DeviceStatus.warning:
        return 'Warning';
      case DeviceStatus.compromised:
        return 'Compromised';
    }
  }

  Color get color {
    switch (this) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        return Colors.grey;
      case DeviceStatus.warning:
        return Colors.orange;
      case DeviceStatus.compromised:
        return Colors.red;
    }
  }
}
