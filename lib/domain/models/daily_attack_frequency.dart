import 'package:equatable/equatable.dart';

/// Model class for daily attack frequency data showing attacks over the past 7 days
class DailyAttackFrequency extends Equatable {
  final List<int> counts;
  final List<String> dates;

  const DailyAttackFrequency({
    required this.counts,
    required this.dates,
  });

  /// Create a DailyAttackFrequency instance from a JSON map
  factory DailyAttackFrequency.fromJson(Map<String, dynamic> json) {
    return DailyAttackFrequency(
      counts: (json['counts'] as List?)?.map((e) => e as int).toList() ?? [],
      dates: (json['dates'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  /// Convert this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'counts': counts,
      'dates': dates,
    };
  }

  @override
  List<Object?> get props => [counts, dates];
}
