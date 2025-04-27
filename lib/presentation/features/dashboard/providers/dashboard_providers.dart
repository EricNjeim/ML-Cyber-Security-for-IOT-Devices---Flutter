import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/network_traffic.dart';

/// Providers related to the dashboard feature
class DashboardProviders {
  /// Provider for network traffic logs
  static final networkTrafficLogsProvider =
      FutureProvider<Result<List<NetworkTraffic>>>((ref) async {
    final useCase = ref.read(ServiceLocator.getNetworkTrafficLogsProvider);
    return await useCase();
  });

  /// Provider for recent attack logs
  static final recentAttacksProvider =
      FutureProvider<Result<List<NetworkTraffic>>>((ref) async {
    final useCase = ref.read(ServiceLocator.getRecentAttacksProvider);
    return await useCase();
  });
}
