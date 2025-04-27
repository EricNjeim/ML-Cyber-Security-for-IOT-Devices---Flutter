import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/domain/models/ongoing_attack.dart';

/// The state for the ongoing attacks
class OngoingAttacksState {
  final AsyncValue<List<OngoingAttack>> attacks;

  OngoingAttacksState({required this.attacks});

  factory OngoingAttacksState.initial() {
    return OngoingAttacksState(attacks: const AsyncValue.loading());
  }

  OngoingAttacksState copyWith({
    AsyncValue<List<OngoingAttack>>? attacks,
  }) {
    return OngoingAttacksState(
      attacks: attacks ?? this.attacks,
    );
  }
}

/// Provider for ongoing attacks state
final ongoingAttacksProvider = StateNotifierProvider<OngoingAttacksNotifier,
    AsyncValue<List<OngoingAttack>>>(
  (ref) => OngoingAttacksNotifier(ref),
);

/// Notifier for ongoing attacks
class OngoingAttacksNotifier
    extends StateNotifier<AsyncValue<List<OngoingAttack>>> {
  final Ref _ref;

  OngoingAttacksNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadOngoingAttacks();
  }

  /// Load ongoing attacks from the repository
  Future<void> loadOngoingAttacks() async {
    state = const AsyncValue.loading();

    final getOngoingAttacks =
        _ref.read(ServiceLocator.getOngoingAttacksProvider);
    final result = await getOngoingAttacks();

    result.fold(
      (attacks) => state = AsyncValue.data(attacks),
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  /// Resolve an attack by ID
  Future<void> resolveAttack(int attackId) async {
    final resolveAttack = _ref.read(ServiceLocator.resolveAttackProvider);
    final result = await resolveAttack(attackId);

    result.fold(
      (success) {
        // If successfully resolved, update the list by removing the resolved attack
        state.whenData((attacks) {
          state = AsyncValue.data(
            attacks.where((attack) => attack.attackId != attackId).toList(),
          );
        });
      },
      (failure) => null, // If failed, we'll keep the UI unchanged
    );
  }
}
