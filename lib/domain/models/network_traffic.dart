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

  const NetworkTraffic({
    required this.category,
    required this.dstport,
    required this.ethDst,
    required this.ethSrc,
    required this.id,
    required this.ipDst,
    required this.ipSrc,
    required this.label,
    required this.srcport,
    required this.timestamp,
  });

  /// Create a NetworkTraffic instance from a JSON map
  factory NetworkTraffic.fromJson(Map<String, dynamic> json) {
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
    );
  }

  /// Convert this instance to a JSON map
  Map<String, dynamic> toJson() {
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
      ];
}
