import 'package:iotframework/domain/entities/network_traffic.dart';

class NetworkTrafficModel extends NetworkTraffic {
  const NetworkTrafficModel({
    required super.id,
    required super.category,
    required super.detectedAs,
    required super.ethDst,
    required super.ethSrc,
    required super.ipDst,
    required super.ipSrc,
    super.tcpDstPort,
    super.tcpSrcPort,
    required super.timestamp,
    super.udpDstPort,
    super.udpSrcPort,
  });

  factory NetworkTrafficModel.fromJson(Map<String, dynamic> json) {
    return NetworkTrafficModel(
      id: json['id'] != null
          ? (json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0)
          : 0,
      category: json['category']?.toString() ?? 'Unknown',
      detectedAs: json['detected_as']?.toString() ?? 'Unknown',
      ethDst: json['eth_dst']?.toString() ?? '',
      ethSrc: json['eth_src']?.toString() ?? '',
      ipDst: json['ip_dst']?.toString() ?? '',
      ipSrc: json['ip_src']?.toString() ?? '',
      tcpDstPort: json['tcp_dstport'] != null
          ? (json['tcp_dstport'] is int
              ? json['tcp_dstport']
              : int.tryParse(json['tcp_dstport'].toString()))
          : null,
      tcpSrcPort: json['tcp_srcport'] != null
          ? (json['tcp_srcport'] is int
              ? json['tcp_srcport']
              : int.tryParse(json['tcp_srcport'].toString()))
          : null,
      timestamp: json['timestamp']?.toString() ?? '',
      udpDstPort: json['udp_dstport'] != null
          ? (json['udp_dstport'] is int
              ? json['udp_dstport']
              : int.tryParse(json['udp_dstport'].toString()))
          : null,
      udpSrcPort: json['udp_srcport'] != null
          ? (json['udp_srcport'] is int
              ? json['udp_srcport']
              : int.tryParse(json['udp_srcport'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'detected_as': detectedAs,
      'eth_dst': ethDst,
      'eth_src': ethSrc,
      'ip_dst': ipDst,
      'ip_src': ipSrc,
      'tcp_dstport': tcpDstPort,
      'tcp_srcport': tcpSrcPort,
      'timestamp': timestamp,
      'udp_dstport': udpDstPort,
      'udp_srcport': udpSrcPort,
    };
  }
}
