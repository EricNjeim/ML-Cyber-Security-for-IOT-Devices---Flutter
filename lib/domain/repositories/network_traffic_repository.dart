import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/network_traffic.dart';

/// Repository for network traffic data
abstract class NetworkTrafficRepository {
  /// Get recent network traffic data
  ///
  /// [limit] specifies the maximum number of records to retrieve
  Future<Result<List<NetworkTraffic>>> getRecentTraffic(int limit);

  /// Get all network traffic logs
  Future<List<NetworkTraffic>> getNetworkTrafficLogs();

  /// Get recent attacks
  Future<List<NetworkTraffic>> getRecentAttacks();
}
