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
    // Auto-ping the network when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(pingAllDevicesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentAttacksAsync = ref.watch(recentAttacksProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final pingAllAsync = ref.watch(pingAllDevicesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(recentAttacksProvider);
        ref.refresh(devicesProvider);
        ref.refresh(pingAllDevicesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttackSummarySection(),
            const SizedBox(height: 24.0),
            _buildNetworkMapSection(devicesAsync, pingAllAsync),
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

  Widget _buildNetworkMapSection(
    AsyncValue<dynamic> devicesAsync,
    AsyncValue<dynamic> pingAllAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Network Status',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => AppRouter.navigateTo(AppRouter.networkRoute),
              icon: const Icon(Icons.fullscreen, size: 20),
              label: const Text('View Full Map'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        _buildNetworkSummaryCard(devicesAsync, pingAllAsync),
      ],
    );
  }

  Widget _buildNetworkSummaryCard(
    AsyncValue<dynamic> devicesAsync,
    AsyncValue<dynamic> pingAllAsync,
  ) {
    return SizedBox(
      height: 200,
      child: DashboardCard(
        title: '',
        child: Stack(
          children: [
            _buildNetworkOverview(devicesAsync, pingAllAsync),
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton.small(
                onPressed: () => ref.refresh(pingAllDevicesProvider),
                backgroundColor: Colors.greenAccent,
                child: const Icon(Icons.refresh, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkOverview(
    AsyncValue<dynamic> devicesAsync,
    AsyncValue<dynamic> pingAllAsync,
  ) {
    return devicesAsync.when(
      data: (devicesResult) {
        if (devicesResult == null) {
          return const Center(child: Text('No data available'));
        }

        return devicesResult.fold(
          (devices) {
            return pingAllAsync.when(
              data: (pingResult) {
                if (pingResult == null) {
                  return _buildNetworkSummary(devices, {});
                }

                return pingResult.fold(
                  (results) => _buildNetworkSummary(devices, results),
                  (failure) => _buildNetworkSummary(devices, {}),
                );
              },
              loading: () => _buildNetworkSummary(devices, {}, isLoading: true),
              error: (_, __) => _buildNetworkSummary(devices, {}),
            );
          },
          (failure) => Center(
            child: Text('Error: ${failure.message}'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildNetworkSummary(
      List<Device> devices, Map<String, PingResult> pingResults,
      {bool isLoading = false}) {
    // Count online/offline devices
    final int total = devices.length;
    final int online =
        pingResults.values.where((result) => result.isReachable).length;
    final int offline = total - online;

    return Stack(
      children: [
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusIndicator(
                      'Total Devices',
                      total.toString(),
                      Colors.blue,
                    ),
                    _buildStatusIndicator(
                      'Online',
                      online.toString(),
                      Colors.green,
                    ),
                    _buildStatusIndicator(
                      'Offline',
                      offline.toString(),
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (total > 0)
                  LinearProgressIndicator(
                    value: total > 0 ? online / total : 0,
                    backgroundColor: Colors.red.withOpacity(0.2),
                    color: Colors.green,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Network Health: ${total > 0 ? ((online / total) * 100).toStringAsFixed(0) : "0"}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
                            title: Text(attack.detectedAs),
                            subtitle: Text(
                                'From: ${attack.ipSrc} - To: ${attack.ipDst}'),
                            trailing: Text(attack.timestamp),
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
                            onPressed: () => ref.refresh(recentAttacksProvider),
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
