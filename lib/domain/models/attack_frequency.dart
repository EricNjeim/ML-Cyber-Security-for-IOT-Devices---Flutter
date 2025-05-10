import 'package:equatable/equatable.dart';

/// Model class for attack frequency data showing distribution of attack types
class AttackFrequency extends Equatable {
  final List<int> counts;
  final List<String> labels;

  const AttackFrequency({
    required this.counts,
    required this.labels,
  });

  /// Create an AttackFrequency instance from a JSON map
  factory AttackFrequency.fromJson(Map<String, dynamic> json) {
    return AttackFrequency(
      counts: (json['counts'] as List?)?.map((e) => e as int).toList() ?? [],
      labels: (json['labels'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  /// Convert this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'counts': counts,
      'labels': labels,
    };
  }

  @override
  List<Object?> get props => [counts, labels];
}
