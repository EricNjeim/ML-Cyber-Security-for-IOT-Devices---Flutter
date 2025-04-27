import 'package:equatable/equatable.dart';

/// Model class representing an ongoing attack
class OngoingAttack extends Equatable {
  final int id;
  final int attackId;
  final String attackType;
  final bool isResolved;
  final DateTime startTime;

  const OngoingAttack({
    required this.id,
    required this.attackId,
    required this.attackType,
    required this.isResolved,
    required this.startTime,
  });

  /// Create an OngoingAttack instance from a JSON map
  factory OngoingAttack.fromJson(Map<String, dynamic> json) {
    return OngoingAttack(
      id: json['id'] ?? 0,
      attackId: json['attack_id'] ?? 0,
      attackType: json['attack_type'] ?? '',
      isResolved: json['is_resolved'] ?? false,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
    );
  }

  /// Convert this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attack_id': attackId,
      'attack_type': attackType,
      'is_resolved': isResolved,
      'start_time': startTime.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        attackId,
        attackType,
        isResolved,
        startTime,
      ];
}
