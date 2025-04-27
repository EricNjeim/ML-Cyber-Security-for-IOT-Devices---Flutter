import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/repositories/attack_repository.dart';

/// Use case to resolve a specific attack by ID
class ResolveAttack {
  final AttackRepository repository;

  ResolveAttack(this.repository);

  /// Resolve the attack with the given ID
  Future<Result<bool>> call(int attackId) => repository.resolveAttack(attackId);
}
