import 'package:equatable/equatable.dart';

/// Model class representing network traffic data
class NetworkTraffic extends Equatable {
  final String category;
  final int dstport;
  final String ethDst;
  final String ethSrc;
  final int id;
  final String ipDst;
  final String ipSrc;
  final String label;
  final int srcport;
  final DateTime timestamp;
  final bool isResolved;

  const NetworkTraffic({
    required this.category,
    this.dstport = 0,
    this.ethDst = '',
    this.ethSrc = '',
    required this.id,
    this.ipDst = '',
    this.ipSrc = '',
    this.label = 'Anomaly',
    this.srcport = 0,
    required this.timestamp,
    this.isResolved = false,
  });

  /// Create a NetworkTraffic instance from a JSON map
  factory NetworkTraffic.fromJson(Map<String, dynamic> json) {
    // Handle new attack API format
    if (json.containsKey('attack_id') || json.containsKey('attack_type')) {
      return NetworkTraffic(
        id: json['attack_id'] ?? json['id'] ?? 0,
        category: json['attack_type'] ?? '',
        timestamp: json['start_time'] != null
            ? DateTime.parse(json['start_time'])
            : DateTime.now(),
        isResolved: json['is_resolved'] ?? false,
        // Default values for fields not in the new format
        dstport: 0,
        ethDst: '',
        ethSrc: '',
        ipDst: '',
        ipSrc: '',
        srcport: 0,
      );
    }

    // Handle original format
    return NetworkTraffic(
      category: json['category'] ?? '',
      dstport: json['dstport'] ?? 0,
      ethDst: json['eth_dst'] ?? '',
      ethSrc: json['eth_src'] ?? '',
      id: json['id'] ?? 0,
      ipDst: json['ip_dst'] ?? '',
      ipSrc: json['ip_src'] ?? '',
      label: json['label'] ?? '',
      srcport: json['srcport'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isResolved: false,
    );
  }

  /// Convert this instance to a JSON map
  Map<String, dynamic> toJson() {
    // Check if this is using the new attack format
    if (dstport == 0 &&
        ethDst.isEmpty &&
        ethSrc.isEmpty &&
        ipDst.isEmpty &&
        ipSrc.isEmpty) {
      return {
        'attack_id': id,
        'attack_type': category,
        'start_time': timestamp.toIso8601String(),
        'is_resolved': isResolved,
      };
    }

    // Original format
    return {
      'category': category,
      'dstport': dstport,
      'eth_dst': ethDst,
      'eth_src': ethSrc,
      'id': id,
      'ip_dst': ipDst,
      'ip_src': ipSrc,
      'label': label,
      'srcport': srcport,
      'timestamp': timestamp.toIso8601String(),
      'is_resolved': isResolved,
    };
  }

  /// Returns true if this traffic entry represents an attack
  bool get isAttack => label != 'normal';

  @override
  List<Object?> get props => [
        id,
        category,
        dstport,
        ethDst,
        ethSrc,
        ipDst,
        ipSrc,
        label,
        srcport,
        timestamp,
        isResolved,
      ];
}
