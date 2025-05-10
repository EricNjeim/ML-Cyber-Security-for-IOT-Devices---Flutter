import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/core/routing/app_router.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/domain/entities/network_traffic.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<Map<String, dynamic>> attackSummaryData = const [
    {'title': 'Today', 'count': 5},
    {'title': 'Week', 'count': 20},
    {'title': 'Month', 'count': 80},
  ];

  @override
  void initState() {
    super.initState();
    // Remove auto-ping as we don't need the network map anymore
  }

  @override
  Widget build(BuildContext context) {
    // Remove devicesAsync and pingAllAsync as they are only needed for network map
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttackSummarySection(),
          const SizedBox(height: 16.0),
          // Network map section removed
          const SizedBox(height: 16.0),
          _buildTrafficSection(),
        ],
      ),
    );
  }

  Widget _buildAttackSummarySection() {
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

  Widget _buildTrafficSection() {
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
}
