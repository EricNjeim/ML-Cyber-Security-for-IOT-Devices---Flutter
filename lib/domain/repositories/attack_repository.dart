import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/ongoing_attack.dart';

/// Repository interface for attack operations
abstract class AttackRepository {
  /// Get all ongoing attacks
  Future<Result<List<OngoingAttack>>> getOngoingAttacks();

  /// Resolve a specific attack by ID
  Future<Result<bool>> resolveAttack(int attackId);
}
