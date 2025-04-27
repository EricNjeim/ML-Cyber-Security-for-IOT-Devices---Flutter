import 'package:equatable/equatable.dart';

class NetworkTraffic extends Equatable {
  final int id;
  final String category;
  final String detectedAs;
  final String ethDst;
  final String ethSrc;
  final String ipDst;
  final String ipSrc;
  final int? tcpDstPort;
  final int? tcpSrcPort;
  final String timestamp;
  final int? udpDstPort;
  final int? udpSrcPort;

  const NetworkTraffic({
    required this.id,
    required this.category,
    required this.detectedAs,
    required this.ethDst,
    required this.ethSrc,
    required this.ipDst,
    required this.ipSrc,
    this.tcpDstPort,
    this.tcpSrcPort,
    required this.timestamp,
    this.udpDstPort,
    this.udpSrcPort,
  });

  @override
  List<Object?> get props => [
        id,
        category,
        detectedAs,
        ethDst,
        ethSrc,
        ipDst,
        ipSrc,
        tcpDstPort,
        tcpSrcPort,
        timestamp,
        udpDstPort,
        udpSrcPort,
      ];
}
