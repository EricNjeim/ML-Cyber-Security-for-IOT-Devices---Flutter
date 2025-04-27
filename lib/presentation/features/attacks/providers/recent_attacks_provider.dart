import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';

/// The state of recent attacks
class RecentAttacksState {
  final List<NetworkTraffic> attacks;
  final bool isLoading;
  final String? errorMessage;

  const RecentAttacksState({
    this.attacks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RecentAttacksState copyWith({
    List<NetworkTraffic>? attacks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecentAttacksState(
      attacks: attacks ?? this.attacks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for managing recent attacks data
class RecentAttacksNotifier extends StateNotifier<RecentAttacksState> {
  final NetworkTrafficRepository _repository;
  Timer? _refreshTimer;

  RecentAttacksNotifier({required NetworkTrafficRepository repository})
      : _repository = repository,
        super(const RecentAttacksState()) {
    // Initial fetch
    fetchRecentAttacks();

    // Setup timer for periodic fetch
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchRecentAttacks();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Fetch recent attacks from the repository
  Future<void> fetchRecentAttacks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getRecentTraffic(10);

    result.fold(
      (networkTraffic) {
        state = state.copyWith(
          attacks: networkTraffic,
          isLoading: false,
        );
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
    );
  }
}

/// Provider for recent attacks
final recentAttacksProvider =
    StateNotifierProvider<RecentAttacksNotifier, RecentAttacksState>((ref) {
  return RecentAttacksNotifier(
    repository: ref.read(ServiceLocator.recentAttacksRepositoryProvider),
  );
});
