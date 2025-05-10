import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/models/attack_frequency.dart';
import 'package:iotframework/domain/models/daily_attack_frequency.dart';

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

  /// Get today's attacks
  Future<List<NetworkTraffic>> getTodayAttacks();

  /// Get week's attacks
  Future<List<NetworkTraffic>> getWeekAttacks();

  /// Get month's attacks
  Future<List<NetworkTraffic>> getMonthAttacks();

  /// Get attack frequency data for all time
  Future<AttackFrequency> getAttackFrequency();

  /// Get daily attack frequency data for the past 7 days
  Future<DailyAttackFrequency> getDailyAttackFrequency();
}
