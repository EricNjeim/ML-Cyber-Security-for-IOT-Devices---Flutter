import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/presentation/features/dashboard/providers/dashboard_providers.dart';
import 'package:iotframework/presentation/features/dashboard/widgets/dashboard_card.dart';
import 'package:fl_chart/fl_chart.dart';

/// Dashboard screen for IoT monitoring
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAttacksAsync =
        ref.watch(DashboardProviders.recentAttacksProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(DashboardProviders.recentAttacksProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttackSummarySection(),
            const SizedBox(height: 24.0),
            _buildTrafficChartSection(),
            const SizedBox(height: 24.0),
            _buildRecentAttacksSection(recentAttacksAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackSummarySection() {
    // Dummy data for attack summary
    final List<Map<String, dynamic>> attackSummaryData = const [
      {'title': 'Today', 'count': 5},
      {'title': 'Week', 'count': 20},
      {'title': 'Month', 'count': 80},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attack Summary',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attackSummaryData.length,
            itemBuilder: (context, index) {
              final item = attackSummaryData[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16.0),
                child: DashboardCard(
                  title: item['title'],
                  backgroundColor: Colors.greenAccent.withOpacity(0.2),
                  titleColor: Colors.green[700],
                  child: Center(
                    child: Text(
                      '${item['count']}',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficChartSection() {
    return SizedBox(
      height: 250,
      child: DashboardCard(
        title: 'Network Traffic',
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  const FlSpot(0, 3),
                  const FlSpot(1, 1),
                  const FlSpot(2, 4),
                  const FlSpot(3, 2),
                  const FlSpot(4, 5),
                  const FlSpot(5, 3),
                  const FlSpot(6, 4),
                ],
                isCurved: true,
                color: Colors.greenAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.greenAccent.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAttacksSection(
      AsyncValue<Result<List<NetworkTraffic>>> recentAttacksAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Attacks',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 300,
          child: recentAttacksAsync.when(
            data: (result) {
              if (result is Result<List<NetworkTraffic>>) {
                return result.fold(
                  (attacks) {
                    if (attacks.isEmpty) {
                      return const Center(
                        child: Text('No recent attacks detected'),
                      );
                    }
                    return ListView.builder(
                      itemCount: attacks.length,
                      itemBuilder: (context, index) {
                        final attack = attacks[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(attack.label),
                            subtitle: Text(
                                'From: ${attack.ipSrc} - To: ${attack.ipDst}'),
                            trailing: Text(
                                '${attack.timestamp.day}/${attack.timestamp.month} ${attack.timestamp.hour}:${attack.timestamp.minute}'),
                          ),
                        );
                      },
                    );
                  },
                  (failure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            failure.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text('Invalid result type'));
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading data: $error'),
            ),
          ),
        ),
      ],
    );
  }
}
