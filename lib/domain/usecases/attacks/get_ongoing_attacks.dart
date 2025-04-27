import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/ongoing_attack.dart';
import 'package:iotframework/domain/repositories/attack_repository.dart';

/// Use case to get all ongoing attacks
class GetOngoingAttacks {
  final AttackRepository repository;

  GetOngoingAttacks(this.repository);

  /// Get all ongoing attacks from the repository
  Future<Result<List<OngoingAttack>>> call() => repository.getOngoingAttacks();
}
