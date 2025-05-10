import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attack Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildAttackTypesChart(context, ref),
              const SizedBox(height: 24),
              _buildDailyAttacksChart(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttackTypesChart(BuildContext context, WidgetRef ref) {
    return Container(
      height: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attack Types Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(attackFrequencyProvider),
                tooltip: 'Refresh data',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final attackFrequencyAsync = ref.watch(attackFrequencyProvider);

                return attackFrequencyAsync.when(
                  data: (result) {
                    return result.fold(
                      (data) => _buildPieChart(data.counts, data.labels),
                      (failure) => Center(
                        child: Text(
                          'Failed to load data: ${failure.message}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<int> counts, List<String> labels) {
    if (counts.isEmpty || labels.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Generate colors for the pie chart sections
    final colors = List.generate(
      counts.length,
      (index) => Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
          .withOpacity(0.8),
    );

    // Map data for the pie chart
    final pieData = List.generate(
      counts.length,
      (index) => MapEntry(labels[index], counts[index]),
    ).where((entry) => entry.value > 0).toList();

    // Calculate the total for percentages
    final total = counts.fold<int>(0, (prev, count) => prev + count);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _generatePieSections(counts, colors, total),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: List.generate(
                pieData.length,
                (index) {
                  final entry = pieData[index];
                  final color = colors[labels.indexOf(entry.key)];
                  final percentage = total > 0
                      ? ((entry.value / total) * 100).toStringAsFixed(1)
                      : '0.0';

                  return _buildLegendItem(
                    color,
                    '${entry.key} (${entry.value})',
                    '$percentage%',
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatePieSections(
    List<int> counts,
    List<Color> colors,
    int total,
  ) {
    return List.generate(
      counts.length,
      (i) {
        final value = counts[i];
        final double percentage = total > 0 ? value / total : 0;

        // Skip sections with 0 count
        if (value <= 0) {
          return PieChartSectionData(
            color: Colors.transparent,
            value: 0,
            title: '',
            radius: 0,
            showTitle: false,
          );
        }

        return PieChartSectionData(
          color: colors[i],
          value: value.toDouble(),
          title: '${(percentage * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: null,
          badgePositionPercentageOffset: 0.98,
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label ($value)',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttacksChart(BuildContext context, WidgetRef ref) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Attack Frequency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(dailyAttackFrequencyProvider),
                tooltip: 'Refresh data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final dailyFrequencyAsync =
                    ref.watch(dailyAttackFrequencyProvider);

                return dailyFrequencyAsync.when(
                  data: (result) {
                    return result.fold(
                      (data) => _buildBarChart(data.counts, data.dates),
                      (failure) => Center(
                        child: Text(
                          'Failed to load data: ${failure.message}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Error: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> counts, List<String> dates) {
    if (counts.isEmpty || dates.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Format dates for display
    final displayDates = dates.map((dateStr) {
      final date = DateTime.parse(dateStr);
      return DateFormat('MM/dd').format(date);
    }).toList();

    // Find maximum count for Y-axis scaling
    final maxCount =
        counts.fold<int>(0, (max, count) => count > max ? count : max);
    final yAxisMax = maxCount == 0 ? 1.0 : (maxCount * 1.2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yAxisMax,
          minY: 0,
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxCount > 5 ? (maxCount / 5) : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= displayDates.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayDates[index],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: List.generate(
            counts.length,
            (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: counts[index].toDouble(),
                    width: 24,
                    color: Colors.greenAccent.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
