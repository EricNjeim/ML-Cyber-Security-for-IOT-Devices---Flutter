import 'package:flutter/foundation.dart';

/// Result of a port scan operation
class PortScanResult {
  final String ipAddress;
  final List<PortInfo> openPorts;
  final String portRange;
  final String status;
  final int totalOpen;

  PortScanResult({
    required this.ipAddress,
    required this.openPorts,
    required this.portRange,
    required this.status,
    required this.totalOpen,
  });

  factory PortScanResult.fromJson(Map<String, dynamic> json) {
    // Handle structure with both device and scan_result fields
    final Map<String, dynamic> scanResult;

    if (json.containsKey('device') && json.containsKey('scan_result')) {
      // Get the scan_result field from the response
      scanResult = json['scan_result'];
    } else if (json.containsKey('scan_result')) {
      // Direct scan_result field
      scanResult = json['scan_result'];
    } else {
      // Assume the json itself is the scan result
      scanResult = json;
    }

    if (scanResult == null) {
      throw Exception('Scan result is null');
    }

    final List<PortInfo> ports = [];
    if (scanResult['open_ports'] != null) {
      for (final port in scanResult['open_ports']) {
        ports.add(PortInfo.fromJson(port));
      }
    }

    return PortScanResult(
      ipAddress: scanResult['ip_address'] ?? '',
      openPorts: ports,
      portRange: scanResult['port_range'] ?? '',
      status: scanResult['status'] ?? 'unknown',
      totalOpen: scanResult['total_open'] ?? 0,
    );
  }
}

/// Information about a specific open port
class PortInfo {
  final int port;
  final String service;

  PortInfo({
    required this.port,
    required this.service,
  });

  factory PortInfo.fromJson(Map<String, dynamic> json) {
    return PortInfo(
      port: json['port'] ?? 0,
      service: json['service'] ?? 'unknown',
    );
  }
}
