import 'package:iotframework/domain/entities/device.dart';

/// Data model for Device entity
class DeviceModel extends Device {
  DeviceModel({
    required String id,
    required String name,
    required String ipAddress,
    required String macAddress,
    required DeviceType type,
    required DeviceStatus status,
    required DateTime lastSeen,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          name: name,
          ipAddress: ipAddress,
          macAddress: macAddress,
          type: type,
          status: status,
          lastSeen: lastSeen,
          metadata: metadata,
        );

  /// Create a DeviceModel from JSON
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    // Default values for fields not present in the API response
    final DateTime lastSeen = json['last_seen'] != null
        ? DateTime.parse(json['last_seen'])
        : DateTime.now();

    final DeviceType type = json['type'] != null
        ? _parseDeviceType(json['type'])
        : DeviceType.other;

    final DeviceStatus status = json['status'] != null
        ? _parseDeviceStatus(json['status'])
        : DeviceStatus.online;

    return DeviceModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown Device',
      ipAddress: json['ip_address'] ?? '',
      macAddress: json['mac_address'] ?? '',
      type: type,
      status: status,
      lastSeen: lastSeen,
      metadata: json['metadata'] ?? {'user_id': json['user_id']},
    );
  }

  /// Convert DeviceModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'mac_address': macAddress,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'last_seen': lastSeen.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Parse device type from string
  static DeviceType _parseDeviceType(String typeStr) {
    switch (typeStr) {
      case 'camera':
        return DeviceType.camera;
      case 'sensor':
        return DeviceType.sensor;
      case 'thermostat':
        return DeviceType.thermostat;
      case 'lightBulb':
        return DeviceType.lightBulb;
      case 'switch':
        return DeviceType.switch_;
      case 'lock':
        return DeviceType.lock;
      default:
        return DeviceType.other;
    }
  }

  /// Parse device status from string
  static DeviceStatus _parseDeviceStatus(String statusStr) {
    switch (statusStr) {
      case 'online':
        return DeviceStatus.online;
      case 'offline':
        return DeviceStatus.offline;
      case 'warning':
        return DeviceStatus.warning;
      case 'compromised':
        return DeviceStatus.compromised;
      default:
        return DeviceStatus.offline;
    }
  }
}
